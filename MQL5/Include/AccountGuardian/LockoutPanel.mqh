//+------------------------------------------------------------------+
//| AccountGuardian - LockoutPanel.mqh                               |
//| The Manual Lockout panel, rulings ML-1 to ML-27 of 2026-10-22:   |
//| chart objects on the EA's own chart, in the upper right corner,  |
//| clear of the banner in the upper left. ITS ONLY WRITES ARE CHART |
//| OBJECTS AND ITS OWN g_ag_panel_ GLOBALS. It decides nothing for  |
//| the guardian: Lock Account records one request, and the EA       |
//| applies it in OnTimer (F13). No file, no GV, no transition, no   |
//| sweep call, no trade call. English text, ASCII source (ML-22).   |
//| The synchronous chart reads, ObjectFind, ObjectGetString and     |
//| ObjectGetInteger, run in OnInit and OnChartEvent only; OnTimer   |
//| reaches AgPanelRefresh, which sets properties and reads none.    |
//+------------------------------------------------------------------+
#ifndef AG_LOCKOUT_PANEL_MQH
#define AG_LOCKOUT_PANEL_MQH

#include <AccountGuardian/ManualLockout.mqh>

#define AG_PANEL_PREFIX      "AG_ML_"
#define AG_PANEL_TOP         24
#define AG_PANEL_WIDTH       320
#define AG_PANEL_FONT        "Arial"
#define AG_PANEL_FONT_SIZE   9
#define AG_PANEL_PART_COUNT  23

#define AG_PANEL_IDLE         0
#define AG_PANEL_CHOOSE       1
#define AG_PANEL_REVIEW       2
#define AG_PANEL_WAIT         3
#define AG_PANEL_LOCKED       4
#define AG_PANEL_UNAVAILABLE  5

//--- the one request Lock Account records; the EA applies it in OnTimer
struct AgManualRequest
  {
   bool     pending;
   int      form;
   int      minutes;
   datetime clicked;   // AgServerNow at the click, the confirmation instant (ML-5)
   datetime end;
  };

AgManualRequest g_ag_panel_request;
bool     g_ag_panel_created      = false;
int      g_ag_panel_stage        = AG_PANEL_IDLE;
int      g_ag_panel_drawn_stage  = -1;
bool     g_ag_panel_note_shown   = false;
int      g_ag_panel_form         = AG_ML_FORM_NONE;
int      g_ag_panel_minutes      = 0;
int      g_ag_panel_hh           = 0;
int      g_ag_panel_mm           = 0;
int      g_ag_panel_review_ticks = 0;
string   g_ag_panel_note         = "";
//--- what the last AgPanelRefresh said, read by the render and the clicks
long     g_ag_panel_login        = 0;
datetime g_ag_panel_current_end  = 0;     // the effective end while LOCKED, else 0
string   g_ag_panel_governing    = "";    // MANUAL_LOCKOUT, or the loss lock reason name
bool     g_ag_panel_can_extend   = false;
string   g_ag_panel_extend_why   = "";
string   g_ag_panel_why          = "";
int      g_ag_panel_positions    = 0;
int      g_ag_panel_pendings     = 0;

string g_ag_panel_parts[AG_PANEL_PART_COUNT] =
  {
   "BG", "TITLE", "OPEN", "P15", "P30", "P60", "PEOD", "CUST_L", "CUST_E", "CUST_B", "TIME_L", "TIME_E",
   "TIME_B", "CLOSE", "L1", "L2", "L3", "L4", "L5", "L6", "LOCK", "BACK", "NOTE"
  };

string AgPanelName(const string part) { return AG_PANEL_PREFIX + part; }

//--- one object, created hidden; x is the distance from the chart's right
//--- edge to the object's left edge, the anchor rule of the right upper
//--- corner. The text is set only when the object is new, so a field the
//--- trader is typing in is never written over.
void AgPanelMake(const string part, const ENUM_OBJECT type, const int x, const int y,
                 const int w, const int h, const string text)
  {
   string name  = AgPanelName(part);
   bool   fresh = (ObjectFind(0, name) < 0);
   if(fresh)
      ObjectCreate(0, name, type, 0, 0, 0);
   ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_RIGHT_UPPER);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   if(type != OBJ_LABEL)
     {
      ObjectSetInteger(0, name, OBJPROP_XSIZE, w);
      ObjectSetInteger(0, name, OBJPROP_YSIZE, h);
     }
   else
      ObjectSetInteger(0, name, OBJPROP_ANCHOR, ANCHOR_LEFT_UPPER);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
   ObjectSetInteger(0, name, OBJPROP_BACK, false);
   ObjectSetInteger(0, name, OBJPROP_ZORDER, 10);
   ObjectSetInteger(0, name, OBJPROP_TIMEFRAMES, OBJ_NO_PERIODS);
   if(type == OBJ_RECTANGLE_LABEL)
     {
      ObjectSetInteger(0, name, OBJPROP_BGCOLOR, C'32,32,32');
      ObjectSetInteger(0, name, OBJPROP_BORDER_TYPE, BORDER_FLAT);
      ObjectSetInteger(0, name, OBJPROP_COLOR, clrDimGray);
      return;
     }
   ObjectSetString(0, name, OBJPROP_FONT, AG_PANEL_FONT);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, AG_PANEL_FONT_SIZE);
   ObjectSetInteger(0, name, OBJPROP_COLOR, (type == OBJ_EDIT) ? clrBlack : clrWhite);
   if(fresh)
      ObjectSetString(0, name, OBJPROP_TEXT, text);
   if(type == OBJ_BUTTON)
     {
      ObjectSetInteger(0, name, OBJPROP_BGCOLOR, C'70,70,70');
      ObjectSetInteger(0, name, OBJPROP_BORDER_COLOR, clrDimGray);
      ObjectSetInteger(0, name, OBJPROP_STATE, false);
     }
   if(type == OBJ_EDIT)
     {
      ObjectSetInteger(0, name, OBJPROP_BGCOLOR, clrWhite);
      ObjectSetInteger(0, name, OBJPROP_READONLY, false);
      ObjectSetInteger(0, name, OBJPROP_ALIGN, ALIGN_CENTER);
     }
  }

//--- every object, hidden until the next render; run again on a deletion,
//--- so a panel deleted from the object list comes back at once
void AgPanelCreate()
  {
   ChartSetInteger(0, CHART_EVENT_OBJECT_DELETE, true);
   AgPanelMake("BG",     OBJ_RECTANGLE_LABEL, 332, AG_PANEL_TOP, AG_PANEL_WIDTH, 28, "");
   AgPanelMake("TITLE",  OBJ_LABEL,  326,  30,   0,  0, " ");
   AgPanelMake("OPEN",   OBJ_BUTTON, 162,  24, 150, 22, "Manual Lockout");
   AgPanelMake("P15",    OBJ_BUTTON, 326,  52, 150, 22, "15 minutes");
   AgPanelMake("P30",    OBJ_BUTTON, 170,  52, 150, 22, "30 minutes");
   AgPanelMake("P60",    OBJ_BUTTON, 326,  78, 150, 22, "1 hour");
   AgPanelMake("PEOD",   OBJ_BUTTON, 170,  78, 150, 22, "End of session");
   AgPanelMake("CUST_L", OBJ_LABEL,  326, 108,   0,  0, "Custom minutes:");
   AgPanelMake("CUST_E", OBJ_EDIT,   170, 104,  70, 22, "");
   AgPanelMake("CUST_B", OBJ_BUTTON,  96, 104,  78, 22, "Custom");
   AgPanelMake("TIME_L", OBJ_LABEL,  326, 138,   0,  0, "End time HH:MM server:");
   AgPanelMake("TIME_E", OBJ_EDIT,   170, 134,  70, 22, "");
   AgPanelMake("TIME_B", OBJ_BUTTON,  96, 134,  78, 22, "End time");
   AgPanelMake("CLOSE",  OBJ_BUTTON, 170, 164, 150, 22, "Close");
   AgPanelMake("L1",     OBJ_LABEL,  326,  30,   0,  0, " ");
   AgPanelMake("L2",     OBJ_LABEL,  326,  48,   0,  0, " ");
   AgPanelMake("L3",     OBJ_LABEL,  326,  66,   0,  0, " ");
   AgPanelMake("L4",     OBJ_LABEL,  326,  84,   0,  0, " ");
   AgPanelMake("L5",     OBJ_LABEL,  326, 102,   0,  0, " ");
   AgPanelMake("L6",     OBJ_LABEL,  326, 120,   0,  0, " ");
   AgPanelMake("LOCK",   OBJ_BUTTON, 326, 146, 150, 24, "Lock Account");
   AgPanelMake("BACK",   OBJ_BUTTON, 170, 146, 150, 24, "Back");
   AgPanelMake("NOTE",   OBJ_LABEL,  326,  54,   0,  0, " ");
   ObjectSetInteger(0, AgPanelName("LOCK"), OBJPROP_BGCOLOR, clrFireBrick);
   g_ag_panel_created     = true;
   g_ag_panel_drawn_stage = -1;   // the next render sets every visibility
   g_ag_panel_note_shown  = false;
  }

//--- OnDeinit: the panel's own objects, by prefix, and nothing else
void AgPanelDelete()
  {
   if(!g_ag_panel_created)
      return;
   g_ag_panel_created = false;   // first, so the delete events recreate nothing
   ObjectsDeleteAll(0, AG_PANEL_PREFIX);
   ChartRedraw(0);
  }

//--- OnInit: an in place re-init keeps every global, so the stage and any
//--- request start afresh here; a request never crosses an init
void AgPanelInitReset()
  {
   g_ag_panel_request.pending = false;
   g_ag_panel_request.form    = AG_ML_FORM_NONE;
   g_ag_panel_request.minutes = 0;
   g_ag_panel_request.clicked = 0;
   g_ag_panel_request.end     = 0;
   g_ag_panel_stage        = AG_PANEL_IDLE;
   g_ag_panel_drawn_stage  = -1;
   g_ag_panel_note_shown   = false;
   g_ag_panel_form         = AG_ML_FORM_NONE;
   g_ag_panel_minutes      = 0;
   g_ag_panel_hh           = 0;
   g_ag_panel_mm           = 0;
   g_ag_panel_review_ticks = 0;
   g_ag_panel_note         = "";
   g_ag_panel_login        = 0;
   g_ag_panel_current_end  = 0;
   g_ag_panel_governing    = "";
   g_ag_panel_can_extend   = false;
   g_ag_panel_extend_why   = "";
   g_ag_panel_why          = "";
   g_ag_panel_positions    = 0;
   g_ag_panel_pendings     = 0;
  }

bool AgPanelShown(const string part, const int stage)
  {
   if(stage == AG_PANEL_IDLE)
      return part == "OPEN";
   if(stage == AG_PANEL_CHOOSE)
      return part == "BG" || part == "TITLE" || part == "P15" || part == "P30" || part == "P60"
          || part == "PEOD" || part == "CUST_L" || part == "CUST_E" || part == "CUST_B"
          || part == "TIME_L" || part == "TIME_E" || part == "TIME_B" || part == "CLOSE";
   if(stage == AG_PANEL_REVIEW)
      return part == "BG" || part == "L1" || part == "L2" || part == "L3" || part == "L4"
          || part == "L5" || part == "L6" || part == "LOCK" || part == "BACK";
   if(stage == AG_PANEL_LOCKED)
      return part == "BG" || part == "L1" || part == "L2" || part == "OPEN";
   return part == "BG" || part == "TITLE";   // WAIT and UNAVAILABLE
  }

int AgPanelHeight(const int stage)
  {
   if(stage == AG_PANEL_CHOOSE)
      return 196;
   if(stage == AG_PANEL_REVIEW)
      return 176;
   if(stage == AG_PANEL_LOCKED)
      return 100;
   return 28;
  }

//--- a label's text; an empty label would show the word Label, so a space
void AgPanelText(const string part, const string text)
  {
   ObjectSetString(0, AgPanelName(part), OBJPROP_TEXT, (text == "") ? " " : text);
  }

//--- a button greyed when a click on it would be refused
void AgPanelEnabled(const string part, const bool enabled)
  {
   ObjectSetInteger(0, AgPanelName(part), OBJPROP_COLOR, enabled ? clrWhite : clrGray);
  }

bool AgPanelAllowed(const int form, const int minutes, const datetime now)
  {
   datetime end = AgManualEndFor(now, form, minutes, 0, 0);
   return AgManualCheckEnd(now, end, form, g_ag_panel_current_end) == AG_ML_OK;
  }

//--- every property from the panel's own globals; sets, never reads
void AgPanelRender(const datetime now)
  {
   if(!g_ag_panel_created)
      return;
   int stage = g_ag_panel_stage;
   if(stage != g_ag_panel_drawn_stage)
     {
      for(int i = 0; i < AG_PANEL_PART_COUNT; i++)
         if(g_ag_panel_parts[i] != "NOTE")
            ObjectSetInteger(0, AgPanelName(g_ag_panel_parts[i]), OBJPROP_TIMEFRAMES,
                             AgPanelShown(g_ag_panel_parts[i], stage) ? OBJ_ALL_PERIODS : OBJ_NO_PERIODS);
      ObjectSetInteger(0, AgPanelName("BG"), OBJPROP_YSIZE, AgPanelHeight(stage));
      ObjectSetInteger(0, AgPanelName("OPEN"), OBJPROP_YDISTANCE, (stage == AG_PANEL_LOCKED) ? 94 : AG_PANEL_TOP);
      ObjectSetInteger(0, AgPanelName("NOTE"), OBJPROP_YDISTANCE,
                       AG_PANEL_TOP + ((stage == AG_PANEL_IDLE) ? 26 : AgPanelHeight(stage)) + 4);
      g_ag_panel_drawn_stage = stage;
     }
   datetime anchor = AgNextDayAnchor(now);
   if(stage == AG_PANEL_IDLE)
     {
      AgPanelText("OPEN", "Manual Lockout");
      AgPanelEnabled("OPEN", true);
     }
   else if(stage == AG_PANEL_CHOOSE)
     {
      AgPanelText("TITLE", (g_ag_panel_current_end > 0) ? "Extend: choose a later end"
                                                        : "Manual Lockout: choose the end");
      AgPanelEnabled("P15", AgPanelAllowed(AG_ML_FORM_DURATION, 15, now));
      AgPanelEnabled("P30", AgPanelAllowed(AG_ML_FORM_DURATION, 30, now));
      AgPanelEnabled("P60", AgPanelAllowed(AG_ML_FORM_DURATION, 60, now));
      AgPanelEnabled("PEOD", AgPanelAllowed(AG_ML_FORM_END_OF_DAY, 0, now));
     }
   else if(stage == AG_PANEL_REVIEW)
     {
      datetime end = AgManualEndFor(now, g_ag_panel_form, g_ag_panel_minutes, g_ag_panel_hh, g_ag_panel_mm);
      AgPanelText("L1", "Account " + (string)g_ag_panel_login);
      AgPanelText("L2", "Lock until " + AgManualStamp(end) + " server");
      AgPanelText("L3", "Length " + AgManualHms((long)(end - now)) + " from now");
      AgPanelText("L4", "Open positions " + (string)g_ag_panel_positions + ", pending orders "
                  + (string)g_ag_panel_pendings);
      AgPanelText("L5", "This lockout cannot be cancelled or shortened.");
      AgPanelText("L6", (end < anchor) ? "A close by the guardian locks until " + AgManualStamp(anchor) : "");
     }
   else if(stage == AG_PANEL_WAIT)
      AgPanelText("TITLE", "Locking...");
   else if(stage == AG_PANEL_LOCKED)
     {
      if(g_ag_panel_governing == AG_MANUAL_REASON_NAME)
         AgPanelText("L1", "Manual Lockout until " + AgManualStamp(g_ag_panel_current_end) + " server");
      else
         AgPanelText("L1", "Locked until " + AgManualStamp(g_ag_panel_current_end) + " server ("
                     + g_ag_panel_governing + ")");
      AgPanelText("L2", AgManualHms((long)(g_ag_panel_current_end - now)) + " left");
      AgPanelText("OPEN", "Extend");
      AgPanelEnabled("OPEN", g_ag_panel_can_extend);
     }
   else
      AgPanelText("TITLE", "Manual Lockout unavailable: " + g_ag_panel_why);
   bool note = (g_ag_panel_note != "");
   AgPanelText("NOTE", g_ag_panel_note);
   if(note != g_ag_panel_note_shown)
     {
      ObjectSetInteger(0, AgPanelName("NOTE"), OBJPROP_TIMEFRAMES, note ? OBJ_ALL_PERIODS : OBJ_NO_PERIODS);
      g_ag_panel_note_shown = note;
     }
   ChartRedraw(0);
  }

void AgPanelRefuse(const string why, const int form, const datetime end, const datetime now)
  {
   g_ag_panel_note = "Refused: " + why;
   AgInfo(AgManualRefusedLine(why, "panel", "-", form, end, now));
  }

//--- a preset, a custom number or an end time chosen: checked now, then the
//--- review (ML-15), whose end moves with the clock until Lock Account
void AgPanelChoose(const int form, const int minutes, const int hh, const int mm, const datetime now)
  {
   datetime end     = AgManualEndFor(now, form, minutes, hh, mm);
   int      outcome = AgManualCheckEnd(now, end, form, g_ag_panel_current_end);
   if(outcome != AG_ML_OK)
     {
      AgPanelRefuse(AgManualRefuseName(outcome), form, end, now);
      return;
     }
   g_ag_panel_form         = form;
   g_ag_panel_minutes      = minutes;
   g_ag_panel_hh           = hh;
   g_ag_panel_mm           = mm;
   g_ag_panel_review_ticks = 0;
   g_ag_panel_note         = "";
   g_ag_panel_stage        = AG_PANEL_REVIEW;
   AgInfo(AgManualPanelLine("review", form, end, now));
  }

//--- OnChartEvent. Stage changes, and on Lock Account the one request
void AgPanelOnEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
  {
   if(!g_ag_panel_created)
      return;
   if(id == CHARTEVENT_OBJECT_DELETE)
     {
      if(StringFind(sparam, AG_PANEL_PREFIX) == 0)
         AgPanelCreate();
      return;
     }
   if(id != CHARTEVENT_OBJECT_CLICK || StringFind(sparam, AG_PANEL_PREFIX) != 0)
      return;
   if((ENUM_OBJECT)ObjectGetInteger(0, sparam, OBJPROP_TYPE) == OBJ_BUTTON)
      ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
   string   part  = StringSubstr(sparam, StringLen(AG_PANEL_PREFIX));
   datetime now   = AgServerNow();
   int      stage = g_ag_panel_stage;
   if(stage == AG_PANEL_IDLE && part == "OPEN")
     {
      g_ag_panel_note  = "";
      g_ag_panel_stage = AG_PANEL_CHOOSE;
     }
   else if(stage == AG_PANEL_LOCKED && part == "OPEN")
     {
      if(g_ag_panel_can_extend)
        {
         g_ag_panel_note  = "";
         g_ag_panel_stage = AG_PANEL_CHOOSE;
        }
      else
         g_ag_panel_note = "Refused: " + g_ag_panel_extend_why;   // ML-33: the note only, no journal line
     }
   else if(stage == AG_PANEL_CHOOSE)
     {
      if(part == "P15")
         AgPanelChoose(AG_ML_FORM_DURATION, 15, 0, 0, now);
      else if(part == "P30")
         AgPanelChoose(AG_ML_FORM_DURATION, 30, 0, 0, now);
      else if(part == "P60")
         AgPanelChoose(AG_ML_FORM_DURATION, 60, 0, 0, now);
      else if(part == "PEOD")
         AgPanelChoose(AG_ML_FORM_END_OF_DAY, 0, 0, 0, now);
      else if(part == "CUST_B")
        {
         int minutes = 0;
         if(AgManualParseMinutes(ObjectGetString(0, AgPanelName("CUST_E"), OBJPROP_TEXT), minutes))
            AgPanelChoose(AG_ML_FORM_DURATION, minutes, 0, 0, now);
         else
            AgPanelRefuse(AgManualRefuseName(AG_ML_INPUT), AG_ML_FORM_DURATION, 0, now);
        }
      else if(part == "TIME_B")
        {
         int hh = 0;
         int mm = 0;
         if(AgManualParseHhMm(ObjectGetString(0, AgPanelName("TIME_E"), OBJPROP_TEXT), hh, mm))
            AgPanelChoose(AG_ML_FORM_END_TIME, 0, hh, mm, now);
         else
            AgPanelRefuse(AgManualRefuseName(AG_ML_INPUT), AG_ML_FORM_END_TIME, 0, now);
        }
      else if(part == "CLOSE")
        {
         g_ag_panel_note  = "";
         g_ag_panel_stage = (g_ag_panel_current_end > 0) ? AG_PANEL_LOCKED : AG_PANEL_IDLE;
        }
     }
   else if(stage == AG_PANEL_REVIEW)
     {
      if(part == "BACK")
        {
         g_ag_panel_note  = "";
         g_ag_panel_stage = AG_PANEL_CHOOSE;
        }
      else if(part == "LOCK")
        {
         datetime end     = AgManualEndFor(now, g_ag_panel_form, g_ag_panel_minutes, g_ag_panel_hh, g_ag_panel_mm);
         int      outcome = AgManualCheckEnd(now, end, g_ag_panel_form, g_ag_panel_current_end);
         if(outcome != AG_ML_OK)
           {
            AgPanelRefuse(AgManualRefuseName(outcome), g_ag_panel_form, end, now);
            g_ag_panel_stage = AG_PANEL_CHOOSE;
           }
         else
           {
            g_ag_panel_request.pending = true;
            g_ag_panel_request.form    = g_ag_panel_form;
            g_ag_panel_request.minutes = (g_ag_panel_form == AG_ML_FORM_DURATION) ? g_ag_panel_minutes : 0;
            g_ag_panel_request.clicked = now;
            g_ag_panel_request.end     = end;
            AgInfo(AgManualPanelLine("lock account clicked", g_ag_panel_form, end, now));
            g_ag_panel_note  = "";
            g_ag_panel_stage = AG_PANEL_WAIT;
           }
        }
     }
   AgPanelRender(now);
  }

//--- OnTimer, every tick after the banner: what the guardian allows now
//--- (ML-12), the review's self cancel after 60 ticks (ML-15), the render
void AgPanelRefresh(const long login, const bool eligible, const string why, const bool locked,
                    const datetime current_end, const string governing, const bool can_extend,
                    const string extend_why, const int positions, const int pendings, const datetime now)
  {
   if(!g_ag_panel_created)
      return;
   g_ag_panel_login       = login;
   g_ag_panel_current_end = locked ? current_end : (datetime)0;
   g_ag_panel_governing   = governing;
   g_ag_panel_can_extend  = can_extend;
   g_ag_panel_extend_why  = extend_why;
   g_ag_panel_why         = why;
   g_ag_panel_positions   = positions;
   g_ag_panel_pendings    = pendings;
   if(g_ag_panel_stage != AG_PANEL_WAIT)
     {
      if(locked)
        {
         if((g_ag_panel_stage != AG_PANEL_CHOOSE && g_ag_panel_stage != AG_PANEL_REVIEW) || !can_extend)
            g_ag_panel_stage = AG_PANEL_LOCKED;
        }
      else if(!eligible)
         g_ag_panel_stage = AG_PANEL_UNAVAILABLE;
      else if(g_ag_panel_stage == AG_PANEL_LOCKED || g_ag_panel_stage == AG_PANEL_UNAVAILABLE)
         g_ag_panel_stage = AG_PANEL_IDLE;
     }
   if(g_ag_panel_stage == AG_PANEL_REVIEW)
     {
      g_ag_panel_review_ticks++;
      if(g_ag_panel_review_ticks >= AG_MANUAL_REVIEW_TICKS)
        {
         g_ag_panel_stage = locked ? AG_PANEL_LOCKED : AG_PANEL_IDLE;
         g_ag_panel_note  = "Review timed out";
         AgInfo(AgManualPanelTimedOutLine(now));
        }
     }
   AgPanelRender(now);
  }

//--- the EA's answer to the request, from OnTimer; the next refresh draws it
void AgPanelApplied(const bool ok, const string why)
  {
   g_ag_panel_note  = ok ? "" : "Refused: " + why;
   g_ag_panel_stage = ok ? AG_PANEL_LOCKED : AG_PANEL_CHOOSE;
  }

#endif // AG_LOCKOUT_PANEL_MQH
