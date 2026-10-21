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
//| THE FORMAT (F1 to F11 of 2026-10-21): line 1 the headline; then, |
//| one blank line between the groups, the account and the time; the |
//| money; the limit and the day result; the state and the event     |
//| lines; the closing lines; the build line last, in the messages   |
//| F9 names. Every field line starts with its emoji, one emoji per  |
//| field everywhere. Lines end "\n". The renderers return plain     |
//| text: the bold headline of F10 is applied by the service at send |
//| time, through AgTgHtmlBold.                                      |
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

//+------------------------------------------------------------------+
//| THE DISPLAY FORMATTERS, F3 to F6                                 |
//+------------------------------------------------------------------+
//--- F4: money rounded to the cent, a comma every three digits, two
//--- decimals; a figure that prints 0.00 carries no minus sign
string AgTgMoneyText(const double v)
  {
   double r = MathRound(v * 100.0) / 100.0;
   string s = AgTgMoney(MathAbs(r));
   int    point = StringFind(s, ".");
   string whole = (point < 0) ? s : StringSubstr(s, 0, point);
   string tail  = (point < 0) ? "" : StringSubstr(s, point);
   string out = "";
   int    n = StringLen(whole);
   for(int i = 0; i < n; i++)
     {
      if(i > 0 && (n - i) % 3 == 0)
         out += ",";
      out += StringSubstr(whole, i, 1);
     }
   return (r < 0.0 ? "-" : "") + out + tail;
  }

//--- F4: the sign of the account currency, which the service reads:
//--- USD, EUR and GBP by their symbols, any other by its ISO code
string AgTgCurrencySign(const string iso)
  {
   if(iso == "USD")
      return "$";
   if(iso == "EUR")
      return "€";
   if(iso == "GBP")
      return "£";
   return iso;
  }

//--- an amount with its currency after it: a symbol at once, a code after a space
string AgTgWithCurrency(const string amount, const string cur)
  {
   if(cur == "")
      return amount;
   if(StringLen(cur) == 1)
      return amount + cur;
   return amount + " " + cur;
  }

//--- F8: the signed day result with its currency, a plus sign above zero
string AgTgSignedWithCurrency(const double v, const string cur)
  {
   double r = MathRound(v * 100.0) / 100.0;
   return AgTgWithCurrency((r > 0.0 ? "+" : "") + AgTgMoneyText(r), cur);
  }

//--- 2 decimals, a "loss" or "profit" word by the sign, rounded first, so a
//--- figure that prints 0.00 always reads as a loss of 0.00
string AgTgSigned(const double v)
  {
   double r = MathRound(v * 100.0) / 100.0;
   if(r > 0.0)
      return "רווח " + AgTgMoneyText(r);
   return "הפסד " + AgTgMoneyText(-r);
  }

//--- F3: DD/MM/YYYY HH:MM, with no seconds
string AgTgStamp(const datetime t)
  {
   string s = TimeToString(t, TIME_DATE | TIME_MINUTES);   // yyyy.mm.dd hh:mi
   return StringSubstr(s, 8, 2) + "/" + StringSubstr(s, 5, 2) + "/" + StringSubstr(s, 0, 4)
        + " " + StringSubstr(s, 11, 5);
  }

//--- F3: the date alone, DD/MM/YYYY
string AgTgDate(const datetime t)
  {
   string s = TimeToString(t, TIME_DATE);
   return StringSubstr(s, 8, 2) + "/" + StringSubstr(s, 5, 2) + "/" + StringSubstr(s, 0, 4);
  }

//--- F5: under 120 s in seconds, under 120 minutes in minutes, longer in
//--- hours and minutes; a minutes count there is 2 or more, an hours count
//--- 2 or more, so only the seconds and the trailing minute take the singular
string AgTgDuration(const long seconds)
  {
   if(seconds < 120)
      return AgHeSeconds(seconds);
   if(seconds < 7200)
      return (string)(seconds / 60) + " דקות";
   long   minutes = (seconds % 3600) / 60;
   string out = (string)(seconds / 3600) + " שעות";
   if(minutes == 1)
      return out + " ודקה אחת";
   if(minutes > 1)
      return out + " ו " + (string)minutes + " דקות";
   return out;
  }

//--- F5: the life sign line's age, "a moment" under 5 s
string AgTgAgo(const long seconds) { return seconds < 5 ? "רגע" : AgTgDuration(seconds); }

//--- two parts joined by a line end, an empty part left out
string AgTgAdd(const string text, const string line)
  {
   if(line == "")
      return text;
   if(text == "")
      return line;
   return text + "\n" + line;
  }

//+------------------------------------------------------------------+
//| F10, applied by the service at send time: the whole text HTML    |
//| escaped, then line 1 wrapped in bold tags. Telegram answering    |
//| 400 to that message has it sent once more as the plain text.     |
//+------------------------------------------------------------------+
string AgTgHtmlEscape(const string text)
  {
   string out = "";
   int    n = StringLen(text);
   for(int i = 0; i < n; i++)
     {
      string ch = StringSubstr(text, i, 1);
      if(ch == "&")
         out += "&amp;";
      else if(ch == "<")
         out += "&lt;";
      else if(ch == ">")
         out += "&gt;";
      else
         out += ch;
     }
   return out;
  }

string AgTgHtmlBold(const string text)
  {
   string escaped = AgTgHtmlEscape(text);
   int    nl = StringFind(escaped, "\n");
   if(nl < 0)
      return "<b>" + escaped + "</b>";
   return "<b>" + StringSubstr(escaped, 0, nl) + "</b>" + StringSubstr(escaped, nl);
  }

//--- the decision to send once more as plain text: a 400 to the HTML form
bool AgTgPlainAfter(const int http, const bool sent_as_html) { return sent_as_html && http == 400; }

//--- F9: the classes whose message carries the build line
bool AgTgCarriesBuild(const string cls)
  {
   return cls == "S1" || cls == "S2+S1" || cls == "S2" || cls == "STATUS" || cls == "REPLY" || cls == "S14";
  }

//+------------------------------------------------------------------+
//| THE COMMON LINES                                                 |
//+------------------------------------------------------------------+
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

//--- the limit line (F2); figures taken under a lock carry the locked wording
string AgTgLimitLine(const int mode, const double limit)
  {
   return (mode == AG_TG_PNL_LOCKED ? "⚙️ מגבלה יומית נעולה: " : "⚙️ מגבלה יומית: ") + AgTgMoneyText(limit);
  }

//--- the day result line (F2): a result that prints 0.00 reads as a loss
string AgTgResultLine(const int mode, const double pnl)
  {
   if(mode == AG_TG_PNL_NONE)
      return "📉 הפסד היום: עדיין לא חושב";
   double r = MathRound(pnl * 100.0) / 100.0;
   if(r > 0.0)
      return "📈 רווח היום: " + AgTgMoneyText(r);
   return "📉 הפסד היום: " + AgTgMoneyText(-r);
  }

//--- the limit and the result group (addendum 1.2); not computed yet, the
//--- result line alone, there being no limit to show
string AgTgPnlLine(const int mode, const double pnl, const double limit)
  {
   if(mode == AG_TG_PNL_NONE)
      return AgTgResultLine(mode, pnl);
   return AgTgLimitLine(mode, limit) + "\n" + AgTgResultLine(mode, pnl);
  }

//--- the account and the time, then the money
string AgTgCommonHead(const AgTgCommon &c)
  {
   return "👤 מס׳ חשבון: " + (string)c.login
        + "\n🕒 זמן: " + AgTgStamp(c.server_t)
        + "\n\n💰 גודל תיק: " + AgTgMoneyText(c.balance)
        + "\n💵 הון: " + AgTgMoneyText(c.equity);
  }

//--- the common lines whole: the head, the limit and the result, the state
string AgTgCommonLines(const AgTgCommon &c)
  {
   return AgTgCommonHead(c) + "\n\n" + AgTgPnlLine(c.pnl_mode, c.pnl, c.limit)
        + "\n\n🛡️ מצב: " + AgTgStateWord(c.state);
  }

//--- a headline, the common lines with the limit and result group given,
//--- then the event lines given
string AgTgMessageWith(const string headline, const AgTgCommon &c, const string group, const string events)
  {
   return headline + "\n\n" + AgTgCommonHead(c) + "\n\n" + group + "\n\n🛡️ מצב: " + AgTgStateWord(c.state)
        + (events == "" ? "" : "\n" + events);
  }

//--- a headline, the common lines, then the event lines given
string AgTgMessage(const string headline, const AgTgCommon &c, const string events)
  {
   return AgTgMessageWith(headline, c, AgTgPnlLine(c.pnl_mode, c.pnl, c.limit), events);
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
//--- the limit line carries both legs; the line of the limit in force is
//--- gone (F7), the limit line showing the same value
string AgTgTextS1(const AgTgCommon &c, const double percent, const double currency, const double enforced,
                  const string cur)
  {
   string group = AgTgLimitLine(c.pnl_mode, c.limit) + ", הנמוך מבין " + AgTgMoney(percent)
                + "% מגודל התיק בתחילת היום לבין " + AgTgWithCurrency(AgTgNum(currency), cur)
                + "\n" + AgTgResultLine(c.pnl_mode, c.pnl);
   return AgTgMessageWith("🟢 השומר הופעל ומגן על החשבון", c, group, "🔓 נעילה: אין");
  }

string AgTgTextS1Restarted(const AgTgCommon &c, const int reason)
  {
   return AgTgMessage("🟢 השומר הופעל מחדש", c,
                      "🔄 סיבת ההפעלה מחדש: " + AgTgReasonWord(reason)
                      + "\n🔓 נעילה: אין");
  }

string AgTgTextS2(const AgTgCommon &c, const int reason)
  {
   AgTgCommon k = c;
   k.state = AG_TG_STATE_NOT_RUNNING;
   return AgTgMessage("🔴 השומר הפסיק לפעול", k,
                      "📝 סיבה: " + AgTgReasonWord(reason)
                      + "\n🚫 השומר אינו מגן על החשבון עד שיופעל שוב");
  }

string AgTgTextS3Refused(const AgTgCommon &c)
  {
   return AgTgMessage("⛔ השומר סירב לפעול", c,
                      "📝 סיבה: ערך המגבלה היומית אינו מהרשימה המותרת"
                      "\n🚫 השומר אינו מגן על החשבון עד שההגדרה תתוקן והשומר יוצמד מחדש");
  }

string AgTgTextS3Second(const AgTgCommon &c)
  {
   return AgTgMessage("⛔ עותק נוסף של השומר סירב לפעול", c,
                      "📝 סיבה: עותק אחר של השומר כבר פועל על החשבון"
                      "\n👍 העותק הקיים ממשיך להגן על החשבון");
  }

string AgTgTextS3Crash(const AgTgCommon &c, const long chain, const long window_seconds)
  {
   return AgTgMessage("🛑 עצירת בטיחות: השומר קרס שוב ושוב", c,
                      "💥 " + AgHeCount(chain, "הפעלות", "הפעלה אחת") + " ברצף "
                      + (chain == 1 ? "הסתיימה" : "הסתיימו") + " בלי עצירה תקינה, בהפרש של עד "
                      + AgTgDuration(window_seconds) + " זו מזו"
                      + "\n🚫 השומר אינו מגן על החשבון ואינו סוגר דבר"
                      + "\n👉 לחידוש: לעצור את השומר, למחוק את קובץ העצירה ולהפעיל מחדש");
  }

string AgTgTextS3Persisted(const AgTgCommon &c, const datetime halt_time)
  {
   return AgTgMessage("🛑 עצירת בטיחות נמשכת אחרי הפעלה מחדש", c,
                      "⏸️ העצירה התחילה בשעה " + AgTgStamp(halt_time)
                      + "\n🚫 השומר אינו מגן על החשבון עד לחידוש ידני");
  }

//--- the sweep line every lock message carries; a zero count is left out,
//--- and with both zero the line is (F6)
string AgTgSweepNow(const long positions, const long pendings)
  {
   if(positions > 0 && pendings > 0)
      return "🧹 סוגר עכשיו " + AgHePositions(positions) + " ומוחק " + AgHePendings(pendings);
   if(positions > 0)
      return "🧹 סוגר עכשיו " + AgHePositions(positions);
   if(pendings > 0)
      return "🧹 מוחק עכשיו " + AgHePendings(pendings);
   return "";
  }

//--- F8: the crossed limit in its own unit, kind 1 the percent leg, 2 the
//--- currency leg, 3 the held floor; the signed day result takes the place
//--- of the day result line, and the message ends with the day done
string AgTgTextS4(const AgTgCommon &c, const int kind, const datetime until, const double percent,
                  const double currency, const double pnl_at_lock, const long positions,
                  const long pendings, const string cur)
  {
   string crossed = AgTgWithCurrency(AgTgMoneyText(c.limit), cur);
   if(kind == 1)
      crossed = AgTgMoney(percent) + "%";
   else if(kind == 2)
      crossed = AgTgWithCurrency(AgTgNum(currency), cur);
   string group = AgTgLimitLine(c.pnl_mode, c.limit)
                + "\n🚨 עברת את ההפסד היומי!! " + crossed
                + "\n📉 סה״כ PNL: " + AgTgSignedWithCurrency(pnl_at_lock, cur);
   string events = AgTgAdd("⏳ נעול עד: " + AgTgStamp(until), AgTgSweepNow(positions, pendings));
   return AgTgMessageWith("🔒 החשבון ננעל: חריגה מהמגבלה היומית", c, group, events + "\n🏁 סיימנו להיום");
  }

//--- kind 4, the give back from the daily peak, which keeps its own wording
string AgTgTextS4Peak(const AgTgCommon &c, const datetime until, const double peak,
                      const double threshold, const double pnl_at_lock, const long positions,
                      const long pendings, const string cur)
  {
   string group = AgTgLimitLine(c.pnl_mode, c.limit)
                + "\n🏔️ שיא הרווח הסגור היום: " + AgTgMoneyText(peak)
                + "\n🎯 סף הנעילה: " + AgTgSigned(threshold)
                + "\n📉 סה״כ PNL: " + AgTgSignedWithCurrency(pnl_at_lock, cur);
   string events = AgTgAdd("⏳ נעול עד: " + AgTgStamp(until), AgTgSweepNow(positions, pendings));
   return AgTgMessageWith("🔒 החשבון ננעל: ירידה מהשיא היומי", c, group, events + "\n🏁 סיימנו להיום");
  }

string AgTgTextS6C(const AgTgCommon &c, const long closed, const long deleted, const long attempts,
                   const long failures, const long seconds)
  {
   string lines = "";
   if(closed > 0)
      lines = AgTgAdd(lines, (closed == 1 ? "📤 נסגרה: " : "📤 נסגרו: ") + AgHePositions(closed));
   if(deleted > 0)
      lines = AgTgAdd(lines, (deleted == 1 ? "🗑️ נמחקה: " : "🗑️ נמחקו: ") + AgHePendings(deleted));
   if(attempts > 0)
      lines = AgTgAdd(lines, "🔢 מספר ניסיונות השליחה: " + (string)attempts);
   if(failures > 0)
      lines = AgTgAdd(lines, "❌ מספר הכשלים: " + (string)failures);
   lines = AgTgAdd(lines, "⌛ משך: " + AgTgDuration(seconds));
   return AgTgMessage("🧹 סגירת הפוזיציות הושלמה", c, lines);
  }

//--- the ticket line and the symbol line of a position or a pending order
string AgTgTicketLines(const ulong ticket, const bool is_order, const string symbol)
  {
   return (is_order ? "🎫 מספר הפקודה: " : "🎫 מספר הפוזיציה: ") + (string)ticket
        + (symbol == "" ? "" : "\n🏷️ " + symbol);
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
                                         ? "🔁 ניסיון חוזר כשהמסחר בסמל ייפתח: " + AgTgStamp(next_open)
                                         : "🔁 ניסיון חוזר כשהמסחר בסמל ייפתח"));
   if(reason == 4)
      return AgTgMessage("⚠️ " + what + ": המסחר בסמל חסום כעת", c,
                         lines + "\n🔁 ניסיון חוזר כשהמסחר בסמל יתאפשר");
   if(reason == 2)
      return AgTgMessage("⚠️ " + what + " אחרי " + AgHeAttempts(hard_stop), c,
                         lines + "\n🔁 השומר ינסה שוב כל " + AgTgDuration(rearm_seconds));
   return AgTgMessage("⚠️ " + what + ": השרת לא ביצע את " + (is_order ? "המחיקה" : "הסגירה"), c,
                      lines + "\n🔁 השומר ינסה שוב כל " + AgTgDuration(rearm_seconds));
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
                      + (attempt <= 1 ? "🔢 נסגרה בניסיון הראשון" : "🔢 נסגרה בניסיון מספר " + (string)attempt));
  }

string AgTgTextS8Released(const AgTgCommon &c, const datetime expired, const double new_limit)
  {
   return AgTgMessage("🔓 הנעילה הסתיימה, יום מסחר חדש", c,
                      "⏰ הנעילה הסתיימה בשעה " + AgTgStamp(expired)
                      + "\n🆕 המגבלה ליום החדש: " + AgTgMoneyText(new_limit));
  }

string AgTgTextS8Again(const AgTgCommon &c, const datetime until)
  {
   return AgTgMessage("🔒 הנעילה חודשה ביום המסחר החדש", c,
                      "ℹ️ ההפסד הפתוח עדיין חוצה את המגבלה של היום החדש"
                      "\n⏳ נעול עד: " + AgTgStamp(until));
  }

string AgTgTextS9(const AgTgCommon &c, const long level, const double room)
  {
   return AgTgMessage("⚠️ התקרבות למגבלה היומית", c,
                      "🌡️ נוצלו " + (string)level + " אחוז מהמגבלה"
                      + "\n📏 נותרו " + AgTgMoneyText(room) + " עד נעילה"
                      + "\nℹ️ זו התראה בלבד, החשבון אינו נעול");
  }

string AgTgTextS10(const AgTgCommon &c, const datetime lost, const datetime back, const long gap)
  {
   return AgTgMessage("📶 החיבור לשרת הברוקר חזר", c,
                      "⏰ החיבור נותק בשעה " + AgTgStamp(lost)
                      + "\n⏰ החיבור חזר בשעה " + AgTgStamp(back)
                      + "\n⌛ משך הניתוק: " + AgTgDuration(gap)
                      + "\nℹ️ בזמן הניתוק השומר לא קיבל החלטות נעילה ולא שלח פקודות");
  }

string AgTgTextS11(const AgTgCommon &c, const datetime from_local, const datetime to_local, const long held)
  {
   string lines = "⏰ טלגרם לא היה זמין מהשעה " + AgTgStamp(from_local) + " עד השעה " + AgTgStamp(to_local);
   if(held > 0)
      lines += "\n📬 מספר ההתראות שהתעכבו: " + (string)held;
   return AgTgMessage("📨 התראות שהתעכבו נשלחות עכשיו", c,
                      lines + "\nℹ️ ההתראות שהתעכבו נשלחות מיד אחרי הודעה זו");
  }

//--- the line under the block follows the guardian's state at the edge:
//--- LOCKED keeps checking, ACTIVE warns, SYNCING and SAFE_HALT add nothing
string AgTgTextS12Blocked(const AgTgCommon &c, const int code)
  {
   string events = "🚧 החסימה: " + AgTgBlockWord(code);
   if(c.state == AG_STATE_LOCKED)
      events += "\n🔁 השומר ימשיך לבדוק ויסגור מיד כשהמסחר יחזור";
   else if(c.state == AG_STATE_ACTIVE)
      events += "\n❗ החסימה בזמן שהחשבון פעיל: אם תהיה חריגה השומר לא יוכל לסגור פוזיציות";
   return AgTgMessage("⛔ המסחר האלגוריתמי חסום, השומר לא יכול לסגור פוזיציות", c, events);
  }

string AgTgTextS12Restored(const AgTgCommon &c)
  {
   return AgTgMessage("✅ המסחר האלגוריתמי חזר", c, "👍 השומר יכול שוב לסגור פוזיציות");
  }

string AgTgTextS14(const AgTgCommon &c, const datetime day_anchor, const double closed_result,
                   const double peak, const long locks, const double new_limit)
  {
   string lines = "📅 יום המסחר שהסתיים: " + AgTgDate(day_anchor)
                + "\n🧾 התוצאה הסגורה של היום שהסתיים: " + AgTgSigned(closed_result)
                + "\n🏔️ שיא הרווח הסגור של היום שהסתיים: " + AgTgMoneyText(peak);
   if(locks > 0)
      lines += "\n🔐 מספר הנעילות ביום שהסתיים: " + (string)locks;
   return AgTgMessage("📊 סיכום יום מסחר", c, lines + "\n🆕 המגבלה ליום החדש: " + AgTgMoneyText(new_limit));
  }

string AgTgTextS15(const AgTgCommon &c)
  {
   return AgTgMessage("🟢 השומר חודש אחרי עצירת בטיחות", c,
                      "🛠️ קובץ העצירה נמחק ידנית, לפי נוהל החידוש");
  }

//--- restart_reason is the in place stop it merges with, -1 when none
string AgTgTextS16(const AgTgCommon &c, const datetime until, const int reason, const int mask,
                   const long positions, const long pendings, const int restart_reason)
  {
   string lines = (restart_reason >= 0 ? "🔄 סיבת ההפעלה מחדש: " + AgTgReasonWord(restart_reason) + "\n" : "")
                + "⏳ נעול עד: " + AgTgStamp(until)
                + "\n🔎 מקור הנעילה: " + AgTgSourceWord(reason, mask);
   return AgTgMessage("🔒 הנעילה שוחזרה בהפעלת השומר", c, AgTgAdd(lines, AgTgSweepNow(positions, pendings)));
  }

//--- how 1 a write failed, 2 quarantined at load
string AgTgTextS17(const AgTgCommon &c, const int kind, const int how)
  {
   if(how == 2)
      return AgTgMessage("⚠️ השומר מצא קובץ פגום", c,
                         "📁 הקובץ: " + AgTgFileWord(kind)
                         + "\nℹ️ הקובץ הועבר להסגר ונוצר קובץ חדש");
   return AgTgMessage("⚠️ השומר לא הצליח לשמור קובץ", c,
                      "📁 הקובץ: " + AgTgFileWord(kind)
                      + (kind == 1 ? "\n❗ הנעילה נשמרת בזיכרון בלבד עד ההפעלה הבאה" : ""));
  }

string AgTgTextS18(const AgTgCommon &c, const long seconds)
  {
   return AgTgMessage("⚠️ ההפעלה הקודמת של השומר נקטעה", c,
                      "⌛ השומר לא פעל במשך " + AgTgDuration(seconds) + " לפני ההפעלה הזו"
                      + "\n📝 סיבה אפשרית: כיבוי המחשב, קריסה או סגירה בכוח");
  }

//--- which: 1 the percent input changed, 2 the currency input, 3 both; the
//--- percent leg as a percent, the currency leg with its currency
string AgTgTextS19Locked(const AgTgCommon &c, const int which, const double percent,
                         const double currency, const double snap, const string cur)
  {
   string entered = ((which & 1) != 0) ? AgTgMoney(percent) + "%" : AgTgWithCurrency(AgTgNum(currency), cur);
   return AgTgMessage("⚠️ שינוי מגבלה נחסם", c,
                      "✏️ המגבלה שהוזנה: " + entered
                      + "\n📌 המגבלה שבתוקף עד סוף הנעילה: " + AgTgMoneyText(snap));
  }

string AgTgTextS19Raise(const AgTgCommon &c, const double live, const double enforced)
  {
   return AgTgMessage("⚠️ הגדלת המגבלה תיכנס לתוקף רק ביום המסחר הבא", c,
                      "✏️ המגבלה שהוזנה: " + AgTgMoneyText(live)
                      + "\n📌 המגבלה שבתוקף היום: " + AgTgMoneyText(enforced));
  }

string AgTgTextS20(const AgTgCommon &c, const long jump)
  {
   return AgTgMessage("⚠️ שעון השרת קפץ ביותר מיום אחד", c,
                      "⏩ תחילת היום קפצה ב " + AgTgDuration(jump)
                      + "\nℹ️ השומר ממשיך לחשב לפי היום החדש");
  }

string AgTgTextS21(const AgTgCommon &c)
  {
   return AgTgMessage("⚠️ קריאת היסטוריית העסקאות נכשלה", c,
                      "ℹ️ השומר לא מקבל החלטות נעילה עד שהקריאה תצליח, ומנסה שוב בכל שנייה");
  }

//--- why: 1 no broker connection, 2 history not stable yet
string AgTgTextS22(const AgTgCommon &c, const long seconds, const int why)
  {
   return AgTgMessage("⚠️ השומר עדיין לא מגן על החשבון", c,
                      "⌛ השומר בסנכרון כבר " + AgTgDuration(seconds)
                      + "\n📝 סיבה: " + (why == 1 ? "אין חיבור לשרת הברוקר" : "היסטוריית העסקאות עדיין לא יציבה"));
  }

string AgTgTextS24(const AgTgCommon &c)
  {
   return AgTgMessage("⛔ עותק אחר של השומר השתלט על החשבון", c,
                      "👥 עותק נוסף של השומר רשם את עצמו כפעיל על אותו חשבון"
                      "\n👉 יש לוודא שהשומר מוצמד לגרף אחד בלבד");
  }

//+------------------------------------------------------------------+
//| THE PERIODIC STATUS, also the command's reply (item 6). hb_age   |
//| is the mutex heartbeat's age in seconds, -1 when it is released |
//| or missing; data_age the snapshot's age, shown when over 90 s,   |
//| -1 for none. The state line and the headline follow c.state.     |
//+------------------------------------------------------------------+
string AgTgTextStatus(const AgTgCommon &c, const long hb_age, const long data_age, const datetime until)
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
         events = "💔 השומר לא עדכן את סימן החיים שלו כבר " + AgTgDuration(hb_age);
      return AgTgMessage(headline, c, events);
     }
   if(c.state == AG_STATE_ACTIVE)
      events = "🔓 נעילה: אין";
   else if(c.state == AG_STATE_LOCKED)
      events = "⏳ נעול עד: " + AgTgStamp(until);
   events = AgTgAdd(events, "💓 סימן חיים: לפני " + AgTgAgo(hb_age < 0 ? 0 : hb_age));
   if(data_age >= 0)
      events = AgTgAdd(events, "📡 עדכון הנתונים האחרון מהשומר: לפני " + AgTgDuration(data_age));
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
                      "💔 השומר לא עדכן את סימן החיים שלו כבר " + AgTgDuration(seconds)
                      + (not_recorded ? "\n📝 סיבה: לא נרשמה" : "")
                      + "\n🚫 הטרמינל פועל, אבל השומר אינו מגן על החשבון"
                      + (ping_on ? "\n📴 סימן החיים לשירות הניטור החיצוני הופסק" : ""));
  }

string AgTgTextNotRunning(const AgTgCommon &c, const long seconds)
  {
   AgTgCommon k = c;
   k.state = AG_TG_STATE_NOT_RUNNING;
   return AgTgMessage("⛔ השומר אינו פועל בטרמינל", k,
                      "⌛ שירות ההתראות פועל כבר " + AgTgDuration(seconds) + " והשומר עדיין לא הופעל"
                      + "\n🚫 השומר אינו מגן על החשבון עד שיוצמד לגרף");
  }

string AgTgTextRespondsAgain(const AgTgCommon &c, const long gap)
  {
   return AgTgMessage("✅ השומר חזר להגיב", c, "⌛ השומר לא הגיב במשך " + AgTgDuration(gap));
  }

//+------------------------------------------------------------------+
//| THE CLOSING LINES: the queue's "not kept" count (1.12), the      |
//| suppressed count of plan 6.4.2 and the delay line of any message |
//| sent more than 60 s after its event (plan 5), a group of their   |
//| own; then the build line, "" for a message that carries none     |
//| (F9). 0 means the line is absent.                                |
//+------------------------------------------------------------------+
string AgTgFinish(const string text, const long not_kept, const long held_back, const long delay_seconds,
                  const string build_line)
  {
   string closing = "";
   if(not_kept > 0)
      closing = AgTgAdd(closing, "📭 מספר ההתראות שלא נשמרו בגלל עומס: " + (string)not_kept);
   if(held_back > 0)
      closing = AgTgAdd(closing, "🔇 מספר האירועים הדומים שלא נשלחו מאז ההודעה הקודמת: " + (string)held_back);
   if(delay_seconds > 0)
      closing = AgTgAdd(closing, "⏱️ נשלחה באיחור של " + AgTgDuration(delay_seconds));
   string out = text + (closing == "" ? "" : "\n\n" + closing);
   return build_line == "" ? out : out + "\n" + build_line;
  }

#endif // AG_ALERT_TEXT_MQH
