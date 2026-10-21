//+------------------------------------------------------------------+
//| AccountGuardian - AlertText.mqh                                  |
//| Every Hebrew message of the alerts service and its renderer,     |
//| TG-1 (B), design addendum items 10 and 13. ALL HEBREW LIVES IN   |
//| THIS FILE, saved as UTF-8 with a byte order mark, the encoding   |
//| the EA's own source carries (plan 6.5.2). Every function here is |
//| a pure function of its arguments: no file, no network call, no  |
//| global variable, no clock. Shared by the service and the vectors |
//| script, which renders each draft with its example values and     |
//| compares the UTF-8 bytes (TG-S8). No trade calls (SPEC 1).       |
//|                                                                  |
//| THE FORMAT (plan 5): line 1 an emoji and a headline; then the    |
//| account, the server time, the balance, the equity, the day's     |
//| result against the limit and the guardian's state; then the      |
//| event lines; the last line the build label. Lines end "\n".      |
//|                                                                  |
//| THE HEBREW SINGULAR (build requirement of 2026-10-21): a count   |
//| written with its noun reads "<n> <plural>" and, at 1, the        |
//| singular noun with the word for one, through AgHeCount alone. A  |
//| count shown as a field value stands under a label of the form    |
//| "number of the ...", which reads right at every value.           |
//+------------------------------------------------------------------+
#ifndef AG_ALERT_TEXT_MQH
#define AG_ALERT_TEXT_MQH

//--- the event codes, the state codes and AgTgMoney; AlertQueue.mqh
//--- includes Persist.mqh, which brings State.mqh and the sweep constants
#include <AccountGuardian/AlertQueue.mqh>

//--- one message's common lines (plan 5). A simple structure: numbers only.
struct AgTgCommon
  {
   long     login;
   datetime server_t;
   double   balance;
   double   equity;
   double   pnl;
   double   limit;
   int      pnl_mode;   // AG_TG_PNL_*
   int      state;      // ENUM_AG_STATE value, or AG_TG_STATE_NOT_RUNNING
  };

//--- the TG-8 (B) command, nine code points, compared with == only
string AgTgCommandText() { return "בדוק אותי"; }

//+------------------------------------------------------------------+
//| THE SINGULAR RULE: "<n> <plural>", and at 1 the singular form    |
//| with the word for one.                                           |
//+------------------------------------------------------------------+
string AgHeCount(const long n, const string plural, const string one)
  {
   if(n == 1)
      return one;
   return (string)n + " " + plural;
  }

string AgHeSeconds(const long n)   { return AgHeCount(n, "שניות", "שנייה אחת"); }
string AgHePositions(const long n) { return AgHeCount(n, "פוזיציות", "פוזיציה אחת"); }
string AgHePendings(const long n)  { return AgHeCount(n, "פקודות ממתינות", "פקודה ממתינה אחת"); }
string AgHeAttempts(const long n)  { return AgHeCount(n, "ניסיונות", "ניסיון אחד"); }

//--- 2 decimals, a "loss" or "profit" word by the sign, rounded first, so a
//--- figure that prints 0.00 always reads as a loss of 0.00
string AgTgSigned(const double v)
  {
   double r = MathRound(v * 100.0) / 100.0;
   if(r > 0.0)
      return "רווח " + AgTgMoney(r);
   return "הפסד " + AgTgMoney(-r);
  }

string AgTgStamp(const datetime t) { return TimeToString(t, TIME_DATE | TIME_SECONDS); }

string AgTgStateWord(const int state)
  {
   switch(state)
     {
      case AG_STATE_ACTIVE:    return "פעיל";
      case AG_STATE_LOCKED:    return "נעול";
      case AG_STATE_SYNCING:   return "בסנכרון";
      case AG_STATE_SAFE_HALT: return "עצירת בטיחות";
     }
   return "לא פועל";
  }

//--- the day's result against the limit (plan 5 field map, addendum 1.2)
string AgTgPnlLine(const int mode, const double pnl, const double limit)
  {
   if(mode == AG_TG_PNL_NONE)
      return "הפסד היום: עדיין לא חושב";
   double r = MathRound(pnl * 100.0) / 100.0;
   bool   locked = (mode == AG_TG_PNL_LOCKED);
   if(r > 0.0)
      return "רווח היום: " + AgTgMoney(r)
           + (locked ? " מול מגבלה נעולה של " : " מול מגבלת הפסד של ") + AgTgMoney(limit);
   return "הפסד היום: " + AgTgMoney(-r)
        + (locked ? " מול מגבלה נעולה של " : " מול מגבלה של ") + AgTgMoney(limit);
  }

string AgTgCommonLines(const AgTgCommon &c)
  {
   return "חשבון: " + (string)c.login
        + "\nשעת שרת: " + AgTgStamp(c.server_t)
        + "\nיתרה: " + AgTgMoney(c.balance)
        + "\nהון: " + AgTgMoney(c.equity)
        + "\n" + AgTgPnlLine(c.pnl_mode, c.pnl, c.limit)
        + "\nמצב השומר: " + AgTgStateWord(c.state);
  }

//--- a headline, the common lines, then the event lines given
string AgTgMessage(const string headline, const AgTgCommon &c, const string events)
  {
   return headline + "\n" + AgTgCommonLines(c) + (events == "" ? "" : "\n" + events);
  }

//+------------------------------------------------------------------+
//| WORDINGS                                                         |
//+------------------------------------------------------------------+
//--- the deinit reason, 0 to 9 (plan 3.2); anything else was not recorded
string AgTgReasonWord(const int reason)
  {
   switch(reason)
     {
      case 0: return "השומר עצר את עצמו";
      case 1: return "השומר הוסר מהגרף";
      case 2: return "השומר נבנה מחדש";
      case 3: return "סמל הגרף או מסגרת הזמן שלו שונו";
      case 4: return "הגרף נסגר";
      case 5: return "הגדרות השומר שונו";
      case 6: return "החשבון בטרמינל הוחלף או שהחיבור אליו אותחל";
      case 7: return "הוחלה תבנית על הגרף";
      case 8: return "ההפעלה נכשלה";
      case 9: return "הטרמינל נסגר";
     }
   return "לא נרשמה";
  }

//--- the account wide block, in the AgTradeBlockName order
string AgTgBlockWord(const int code)
  {
   switch(code)
     {
      case 1: return "כפתור המסחר האלגוריתמי בטרמינל כבוי";
      case 2: return "המסחר האלגוריתמי כבוי בהגדרות השומר";
      case 3: return "החשבון אינו מאפשר מסחר, ייתכן שנכנסו בסיסמת צפייה";
      case 4: return "הברוקר אינו מאפשר מסחר אוטומטי בחשבון";
     }
   return "כפתור המסחר האלגוריתמי בטרמינל כבוי";
  }

//--- S16's lock source: the reason first, then the local witnesses, then history
string AgTgSourceWord(const int reason, const int mask)
  {
   if(reason == AG_LOCK_CORRUPT_STATE)
      return "קובץ מצב הנעילה פגום, הנעילה נמשכת עד תחילת יום המסחר הבא";
   if((mask & 1) != 0 && (mask & 2) != 0)
      return "קובץ מצב הנעילה ומשתנה הגיבוי בטרמינל";
   if((mask & 1) != 0)
      return "קובץ מצב הנעילה";
   if((mask & 2) != 0)
      return "משתנה הגיבוי בטרמינל";
   if(reason == AG_LOCK_SWEEP_WITNESS)
      return "עסקאות הסגירה של השומר מהיום";
   return "היסטוריית העסקאות בשרת";
  }

//--- S17's file, by the kind the EA reports
string AgTgFileWord(const int kind)
  {
   switch(kind)
     {
      case 1: return "קובץ מצב הנעילה";
      case 2: return "קובץ העצירה";
      case 3: return "קובץ המגבלה שנשמרה מול הגדלה";
      case 4: return "קובץ שיא הרווח הסגור";
      case 5: return "קובץ תור ההתראות";
     }
   return "קובץ של השומר";
  }

//+------------------------------------------------------------------+
//| THE MESSAGES, one function each, in the catalog's order          |
//+------------------------------------------------------------------+
string AgTgTextS1(const AgTgCommon &c, const double percent, const double currency, const double enforced)
  {
   return AgTgMessage("🟢 השומר הופעל ומגן על החשבון", c,
                      "מגבלה באחוזים: " + AgTgMoney(percent) + " אחוז מהיתרה בתחילת היום"
                      + "\nמגבלה בסכום קבוע: " + AgTgNum(currency)
                      + "\nהמגבלה שבתוקף כעת: " + AgTgMoney(enforced)
                      + "\nנעילה: אין");
  }

string AgTgTextS1Restarted(const AgTgCommon &c, const int reason, const double enforced)
  {
   return AgTgMessage("🟢 השומר הופעל מחדש", c,
                      "סיבת ההפעלה מחדש: " + AgTgReasonWord(reason)
                      + "\nהמגבלה שבתוקף כעת: " + AgTgMoney(enforced)
                      + "\nנעילה: אין");
  }

string AgTgTextS2(const AgTgCommon &c, const int reason)
  {
   AgTgCommon k = c;
   k.state = AG_TG_STATE_NOT_RUNNING;
   return AgTgMessage("🔴 השומר הפסיק לפעול", k,
                      "סיבה: " + AgTgReasonWord(reason)
                      + "\nהשומר אינו מגן על החשבון עד שיופעל שוב");
  }

string AgTgTextS3Refused(const AgTgCommon &c)
  {
   return AgTgMessage("⛔ השומר סירב לפעול", c,
                      "סיבה: ערך המגבלה היומית אינו מהרשימה המותרת"
                      "\nהשומר אינו מגן על החשבון עד שההגדרה תתוקן והשומר יוצמד מחדש");
  }

string AgTgTextS3Second(const AgTgCommon &c)
  {
   return AgTgMessage("⛔ עותק נוסף של השומר סירב לפעול", c,
                      "סיבה: עותק אחר של השומר כבר פועל על החשבון"
                      "\nהעותק הקיים ממשיך להגן על החשבון");
  }

string AgTgTextS3Crash(const AgTgCommon &c, const long chain, const long window_seconds)
  {
   return AgTgMessage("🛑 עצירת בטיחות: השומר קרס שוב ושוב", c,
                      AgHeCount(chain, "הפעלות", "הפעלה אחת") + " ברצף "
                      + (chain == 1 ? "הסתיימה" : "הסתיימו") + " בלי עצירה תקינה, בהפרש של עד "
                      + AgHeSeconds(window_seconds) + " זו מזו"
                      + "\nהשומר אינו מגן על החשבון ואינו סוגר דבר"
                      + "\nלחידוש: לעצור את השומר, למחוק את קובץ העצירה ולהפעיל מחדש");
  }

string AgTgTextS3Persisted(const AgTgCommon &c, const datetime halt_time)
  {
   return AgTgMessage("🛑 עצירת בטיחות נמשכת אחרי הפעלה מחדש", c,
                      "העצירה התחילה בשעה " + AgTgStamp(halt_time)
                      + "\nהשומר אינו מגן על החשבון עד לחידוש ידני");
  }

//--- the lines every lock message closes with
string AgTgSweepNow(const long positions, const long pendings)
  {
   return "השומר סוגר עכשיו " + AgHePositions(positions) + " ומוחק " + AgHePendings(pendings);
  }

//--- kind 1 the percent leg, 2 the currency leg, 3 the held floor
string AgTgTextS4(const AgTgCommon &c, const int kind, const datetime until, const double percent,
                  const double currency, const double pnl_at_lock, const long positions,
                  const long pendings)
  {
   string crossed = "מגבלה שנקבעה מוקדם יותר היום ונשמרה מול הגדלה";
   if(kind == 1)
      crossed = "המגבלה היומית באחוזים, " + AgTgMoney(percent) + " אחוז מהיתרה בתחילת היום";
   else if(kind == 2)
      crossed = "המגבלה היומית בסכום קבוע של " + AgTgNum(currency);
   return AgTgMessage("🔒 החשבון ננעל: חריגה מהמגבלה היומית", c,
                      "נעול עד: " + AgTgStamp(until)
                      + "\nהמגבלה שנחצתה: " + crossed
                      + "\nהתוצאה ברגע הנעילה: " + AgTgSigned(pnl_at_lock)
                      + "\n" + AgTgSweepNow(positions, pendings));
  }

//--- kind 4, the give back from the daily peak
string AgTgTextS4Peak(const AgTgCommon &c, const datetime until, const double peak,
                      const double threshold, const double pnl_at_lock, const long positions,
                      const long pendings)
  {
   return AgTgMessage("🔒 החשבון ננעל: ירידה מהשיא היומי", c,
                      "נעול עד: " + AgTgStamp(until)
                      + "\nשיא הרווח הסגור היום: " + AgTgMoney(peak)
                      + "\nסף הנעילה: " + AgTgSigned(threshold)
                      + "\nהתוצאה ברגע הנעילה: " + AgTgSigned(pnl_at_lock)
                      + "\n" + AgTgSweepNow(positions, pendings));
  }

string AgTgTextS6C(const AgTgCommon &c, const long closed, const long deleted, const long attempts,
                   const long failures, const long seconds)
  {
   return AgTgMessage("🧹 סגירת הפוזיציות הושלמה", c,
                      (closed == 1 ? "נסגרה: " : "נסגרו: ") + AgHePositions(closed)
                      + "\n" + (deleted == 1 ? "נמחקה: " : "נמחקו: ") + AgHePendings(deleted)
                      + "\nמספר ניסיונות השליחה: " + (string)attempts
                      + "\nמספר הכשלים: " + (string)failures
                      + "\nמשך: " + AgHeSeconds(seconds));
  }

//--- the ticket line and the symbol line of a position or a pending order
string AgTgTicketLines(const ulong ticket, const bool is_order, const string symbol)
  {
   return (is_order ? "מספר הפקודה: " : "מספר הפוזיציה: ") + (string)ticket
        + (symbol == "" ? "" : "\n" + symbol);
  }

//--- reason 1 session closed, 2 hard stop, 3 refuse, 4 trade mode disabled,
//--- 5 a hold class retcode; next_open 0 when unknown
string AgTgTextS6H(const AgTgCommon &c, const ulong ticket, const bool is_order, const int reason,
                   const string symbol, const datetime next_open, const long hard_stop,
                   const long rearm_seconds)
  {
   string what = is_order ? "פקודה ממתינה לא נמחקה" : "פוזיציה לא נסגרה";
   string lines = AgTgTicketLines(ticket, is_order, symbol);
   if(reason == 1)
      return AgTgMessage("⚠️ " + what + ": המסחר בסמל סגור כעת", c,
                         lines + "\n" + (next_open > 0
                                         ? "ניסיון חוזר כשהמסחר בסמל ייפתח: " + AgTgStamp(next_open)
                                         : "ניסיון חוזר כשהמסחר בסמל ייפתח"));
   if(reason == 4)
      return AgTgMessage("⚠️ " + what + ": המסחר בסמל חסום כעת", c,
                         lines + "\nניסיון חוזר כשהמסחר בסמל יתאפשר");
   if(reason == 2)
      return AgTgMessage("⚠️ " + what + " אחרי " + AgHeAttempts(hard_stop), c,
                         lines + "\nהשומר ינסה שוב כל " + AgHeSeconds(rearm_seconds));
   return AgTgMessage("⚠️ " + what + ": השרת לא ביצע את " + (is_order ? "המחיקה" : "הסגירה"), c,
                      lines + "\nהשומר ינסה שוב כל " + AgHeSeconds(rearm_seconds));
  }

string AgTgTextS6F(const AgTgCommon &c, const ulong ticket, const bool is_order, const string symbol)
  {
   return AgTgMessage(is_order ? "🧹 פקודה ממתינה שלא נמחקה קודם נמחקה עכשיו"
                               : "🧹 פוזיציה שלא נסגרה קודם נסגרה עכשיו",
                      c, AgTgTicketLines(ticket, is_order, symbol));
  }

string AgTgTextS7(const AgTgCommon &c, const ulong ticket, const string symbol, const long attempt)
  {
   return AgTgMessage("🧹 עסקה שנפתחה בזמן הנעילה נסגרה", c,
                      AgTgTicketLines(ticket, false, symbol) + "\n"
                      + (attempt <= 1 ? "נסגרה בניסיון הראשון" : "נסגרה בניסיון מספר " + (string)attempt));
  }

string AgTgTextS8Released(const AgTgCommon &c, const datetime expired, const double new_limit)
  {
   return AgTgMessage("🔓 הנעילה הסתיימה, יום מסחר חדש", c,
                      "הנעילה הסתיימה בשעה " + AgTgStamp(expired)
                      + "\nהמגבלה ליום החדש: " + AgTgMoney(new_limit));
  }

string AgTgTextS8Again(const AgTgCommon &c, const datetime until)
  {
   return AgTgMessage("🔒 הנעילה חודשה ביום המסחר החדש", c,
                      "ההפסד הפתוח עדיין חוצה את המגבלה של היום החדש"
                      "\nנעול עד: " + AgTgStamp(until));
  }

string AgTgTextS9(const AgTgCommon &c, const long level, const double room)
  {
   return AgTgMessage("⚠️ התקרבות למגבלה היומית", c,
                      "נוצלו " + (string)level + " אחוז מהמגבלה"
                      + "\nנותרו " + AgTgMoney(room) + " עד נעילה"
                      + "\nזו התראה בלבד, החשבון אינו נעול");
  }

string AgTgTextS10(const AgTgCommon &c, const datetime lost, const datetime back, const long gap)
  {
   return AgTgMessage("📶 החיבור לשרת הברוקר חזר", c,
                      "החיבור נותק בשעה " + AgTgStamp(lost)
                      + "\nהחיבור חזר בשעה " + AgTgStamp(back)
                      + "\nמשך הניתוק: " + AgHeSeconds(gap)
                      + "\nבזמן הניתוק השומר לא קיבל החלטות נעילה ולא שלח פקודות");
  }

string AgTgTextS11(const AgTgCommon &c, const datetime from_local, const datetime to_local, const long held)
  {
   return AgTgMessage("📨 התראות שהתעכבו נשלחות עכשיו", c,
                      "טלגרם לא היה זמין מהשעה " + TimeToString(from_local, TIME_SECONDS)
                      + " עד השעה " + TimeToString(to_local, TIME_SECONDS)
                      + "\nמספר ההתראות שהתעכבו: " + (string)held
                      + "\nההתראות שהתעכבו נשלחות מיד אחרי הודעה זו");
  }

//--- the line under the block follows the guardian's state at the edge:
//--- LOCKED keeps checking, ACTIVE warns, SYNCING and SAFE_HALT add nothing
string AgTgTextS12Blocked(const AgTgCommon &c, const int code)
  {
   string events = "החסימה: " + AgTgBlockWord(code);
   if(c.state == AG_STATE_LOCKED)
      events += "\nהשומר ימשיך לבדוק ויסגור מיד כשהמסחר יחזור";
   else if(c.state == AG_STATE_ACTIVE)
      events += "\nהחסימה בזמן שהחשבון פעיל: אם תהיה חריגה השומר לא יוכל לסגור פוזיציות";
   return AgTgMessage("⛔ המסחר האלגוריתמי חסום, השומר לא יכול לסגור פוזיציות", c, events);
  }

string AgTgTextS12Restored(const AgTgCommon &c)
  {
   return AgTgMessage("✅ המסחר האלגוריתמי חזר", c, "השומר יכול שוב לסגור פוזיציות");
  }

string AgTgTextS14(const AgTgCommon &c, const datetime day_anchor, const double closed_result,
                   const double peak, const long locks, const double new_limit)
  {
   return AgTgMessage("📊 סיכום יום מסחר", c,
                      "יום המסחר שהסתיים: " + TimeToString(day_anchor, TIME_DATE)
                      + "\nהתוצאה הסגורה של היום שהסתיים: " + AgTgSigned(closed_result)
                      + "\nשיא הרווח הסגור של היום שהסתיים: " + AgTgMoney(peak)
                      + "\nמספר הנעילות ביום שהסתיים: " + (string)locks
                      + "\nהמגבלה ליום החדש: " + AgTgMoney(new_limit));
  }

string AgTgTextS15(const AgTgCommon &c)
  {
   return AgTgMessage("🟢 השומר חודש אחרי עצירת בטיחות", c,
                      "קובץ העצירה נמחק ידנית, לפי נוהל החידוש");
  }

//--- restart_reason is the in place stop it merges with, -1 when none
string AgTgTextS16(const AgTgCommon &c, const datetime until, const int reason, const int mask,
                   const long positions, const long pendings, const int restart_reason)
  {
   return AgTgMessage("🔒 הנעילה שוחזרה בהפעלת השומר", c,
                      (restart_reason >= 0 ? "סיבת ההפעלה מחדש: " + AgTgReasonWord(restart_reason) + "\n" : "")
                      + "נעול עד: " + AgTgStamp(until)
                      + "\nמקור הנעילה: " + AgTgSourceWord(reason, mask)
                      + "\n" + AgTgSweepNow(positions, pendings));
  }

//--- how 1 a write failed, 2 quarantined at load
string AgTgTextS17(const AgTgCommon &c, const int kind, const int how)
  {
   if(how == 2)
      return AgTgMessage("⚠️ השומר מצא קובץ פגום", c,
                         "הקובץ: " + AgTgFileWord(kind)
                         + "\nהקובץ הועבר להסגר ונוצר קובץ חדש");
   return AgTgMessage("⚠️ השומר לא הצליח לשמור קובץ", c,
                      "הקובץ: " + AgTgFileWord(kind)
                      + (kind == 1 ? "\nהנעילה נשמרת בזיכרון בלבד עד ההפעלה הבאה" : ""));
  }

string AgTgTextS18(const AgTgCommon &c, const long seconds)
  {
   return AgTgMessage("⚠️ ההפעלה הקודמת של השומר נקטעה", c,
                      "השומר לא פעל במשך " + AgHeSeconds(seconds) + " לפני ההפעלה הזו"
                      + "\nסיבה אפשרית: כיבוי המחשב, קריסה או סגירה בכוח");
  }

//--- which: 1 the percent input changed, 2 the currency input, 3 both
string AgTgTextS19Locked(const AgTgCommon &c, const int which, const double percent,
                         const double currency, const double snap)
  {
   string entered = ((which & 1) != 0) ? AgTgMoney(percent) + " אחוז" : AgTgNum(currency);
   return AgTgMessage("⚠️ שינוי מגבלה נחסם", c,
                      "המגבלה שהוזנה: " + entered
                      + "\nהמגבלה שבתוקף עד סוף הנעילה: " + AgTgMoney(snap));
  }

string AgTgTextS19Raise(const AgTgCommon &c, const double live, const double enforced)
  {
   return AgTgMessage("⚠️ הגדלת המגבלה תיכנס לתוקף רק ביום המסחר הבא", c,
                      "המגבלה שהוזנה: " + AgTgMoney(live)
                      + "\nהמגבלה שבתוקף היום: " + AgTgMoney(enforced));
  }

string AgTgTextS20(const AgTgCommon &c, const long jump)
  {
   return AgTgMessage("⚠️ שעון השרת קפץ ביותר מיום אחד", c,
                      "תחילת היום קפצה ב " + AgHeSeconds(jump)
                      + "\nהשומר ממשיך לחשב לפי היום החדש");
  }

string AgTgTextS21(const AgTgCommon &c)
  {
   return AgTgMessage("⚠️ קריאת היסטוריית העסקאות נכשלה", c,
                      "השומר לא מקבל החלטות נעילה עד שהקריאה תצליח, ומנסה שוב בכל שנייה");
  }

//--- why: 1 no broker connection, 2 history not stable yet
string AgTgTextS22(const AgTgCommon &c, const long seconds, const int why)
  {
   return AgTgMessage("⚠️ השומר עדיין לא מגן על החשבון", c,
                      "השומר בסנכרון כבר " + AgHeSeconds(seconds)
                      + "\nסיבה: " + (why == 1 ? "אין חיבור לשרת הברוקר" : "היסטוריית העסקאות עדיין לא יציבה"));
  }

string AgTgTextS24(const AgTgCommon &c)
  {
   return AgTgMessage("⛔ עותק אחר של השומר השתלט על החשבון", c,
                      "עותק נוסף של השומר רשם את עצמו כפעיל על אותו חשבון"
                      "\nיש לוודא שהשומר מוצמד לגרף אחד בלבד");
  }

//+------------------------------------------------------------------+
//| THE PERIODIC STATUS, also the command's reply (item 6). hb_age   |
//| is the mutex heartbeat's age in seconds, -1 when it is released |
//| or missing; data_age the snapshot's age, shown when over 90 s,   |
//| -1 for none. The state line and the headline follow c.state.     |
//+------------------------------------------------------------------+
string AgTgTextStatus(const AgTgCommon &c, const long hb_age, const long data_age,
                      const datetime until, const double enforced)
  {
   string headline = "🔴 השומר אינו פועל ואינו מגן על החשבון";
   if(c.state == AG_STATE_ACTIVE)
      headline = "🟢 השומר פועל ומגן על החשבון";
   else if(c.state == AG_STATE_LOCKED)
      headline = "🔒 השומר פועל, החשבון נעול";
   else if(c.state == AG_STATE_SYNCING)
      headline = "⚠️ השומר פועל אבל עדיין לא מגן על החשבון";
   else if(c.state == AG_STATE_SAFE_HALT)
      headline = "🛑 השומר בעצירת בטיחות ואינו מגן על החשבון";
   string events = "";
   if(c.state == AG_TG_STATE_NOT_RUNNING)
     {
      if(hb_age >= 0)
         events = "השומר לא עדכן את סימן החיים שלו כבר " + AgHeSeconds(hb_age);
      return AgTgMessage(headline, c, events);
     }
   events = "בדיקה תקופתית: השומר עדכן את סימן החיים שלו לפני " + AgHeSeconds(hb_age < 0 ? 0 : hb_age);
   if(data_age >= 0)
      events += "\nעדכון הנתונים האחרון מהשומר: לפני " + AgHeSeconds(data_age);
   if(c.state == AG_STATE_ACTIVE)
      events += "\nנעילה: אין\nהמגבלה שבתוקף כעת: " + AgTgMoney(enforced);
   else if(c.state == AG_STATE_LOCKED)
      events += "\nנעול עד: " + AgTgStamp(until);
   return AgTgMessage(headline, c, events);
  }

//+------------------------------------------------------------------+
//| THE GUARDIAN'S LIVENESS, seen by the service (item 4)            |
//+------------------------------------------------------------------+
//--- not_recorded: released with no stop event; ping_on: the network
//--- heartbeat channel is on, so its pings stop with this
string AgTgTextNotResponding(const AgTgCommon &c, const long seconds, const bool not_recorded,
                             const bool ping_on)
  {
   AgTgCommon k = c;
   k.state = AG_TG_STATE_NOT_RUNNING;
   return AgTgMessage("⛔ השומר הפסיק להגיב", k,
                      "השומר לא עדכן את סימן החיים שלו כבר " + AgHeSeconds(seconds)
                      + (not_recorded ? "\nסיבה: לא נרשמה" : "")
                      + "\nהטרמינל פועל, אבל השומר אינו מגן על החשבון"
                      + (ping_on ? "\nסימן החיים לשירות הניטור החיצוני הופסק" : ""));
  }

string AgTgTextNotRunning(const AgTgCommon &c, const long seconds)
  {
   AgTgCommon k = c;
   k.state = AG_TG_STATE_NOT_RUNNING;
   return AgTgMessage("⛔ השומר אינו פועל בטרמינל", k,
                      "שירות ההתראות פועל כבר " + AgHeSeconds(seconds) + " והשומר עדיין לא הופעל"
                      + "\nהשומר אינו מגן על החשבון עד שיוצמד לגרף");
  }

string AgTgTextRespondsAgain(const AgTgCommon &c, const long gap)
  {
   return AgTgMessage("✅ השומר חזר להגיב", c, "השומר לא הגיב במשך " + AgHeSeconds(gap));
  }

//+------------------------------------------------------------------+
//| THE CLOSING LINES: the queue's "not kept" count (1.12), the      |
//| suppressed count of plan 6.4.2, the delay line of any message    |
//| sent more than 60 s after its event (plan 5), then the build.    |
//| 0 means the line is absent.                                      |
//+------------------------------------------------------------------+
string AgTgFinish(const string text, const long not_kept, const long held_back, const long delay_seconds,
                  const string build_line)
  {
   string out = text;
   if(not_kept > 0)
      out += "\nמספר ההתראות שלא נשמרו בגלל עומס: " + (string)not_kept;
   if(held_back > 0)
      out += "\nמספר האירועים הדומים שלא נשלחו מאז ההודעה הקודמת: " + (string)held_back;
   if(delay_seconds > 0)
      out += "\nנשלחה באיחור של " + AgHeSeconds(delay_seconds);
   return out + "\n" + build_line;
  }

#endif // AG_ALERT_TEXT_MQH
