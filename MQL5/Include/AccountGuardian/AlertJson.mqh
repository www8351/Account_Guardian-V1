//+------------------------------------------------------------------+
//| AccountGuardian - AlertJson.mqh                                  |
//| The alerts service's pure helpers, TG-1 (B), design addendum     |
//| items 0.4, 5, 6 and 10: JSON escaping, a flat JSON reader for    |
//| the Bot API answers, the exact match of the one read only        |
//| command (TG-8 (B)), the checks of the three inputs, the status   |
//| slot (TG-15 (A)) and the UTF-8 conversions. Every function here  |
//| is a pure function of its arguments: no file, no network call,   |
//| no global variable, no clock. Shared by the service and the      |
//| vectors script. ASCII only. No trade calls (SPEC 1).             |
//+------------------------------------------------------------------+
#ifndef AG_ALERT_JSON_MQH
#define AG_ALERT_JSON_MQH

#define AG_JSON_STRING 1
#define AG_JSON_NUMBER 2
#define AG_JSON_TRUE   3
#define AG_JSON_FALSE  4
#define AG_JSON_NULL   5
#define AG_JSON_MAX_DEPTH 32

//+------------------------------------------------------------------+
//| Escaping for a JSON string value. Quote, backslash and control   |
//| characters are escaped; every other character, Hebrew and the    |
//| emoji included, passes as itself and becomes UTF-8 at the send.  |
//+------------------------------------------------------------------+
string AgJsonHex4(const int v)
  {
   string digits = "0123456789abcdef";
   string s = "";
   for(int shift = 12; shift >= 0; shift -= 4)
      s += StringSubstr(digits, (v >> shift) & 15, 1);
   return s;
  }

string AgJsonEscape(const string s)
  {
   string out = "";
   int n = StringLen(s);
   for(int i = 0; i < n; i++)
     {
      ushort ch = StringGetCharacter(s, i);
      if(ch == '"')
         out += "\\\"";
      else if(ch == '\\')
         out += "\\\\";
      else if(ch == '\n')
         out += "\\n";
      else if(ch == '\r')
         out += "\\r";
      else if(ch == '\t')
         out += "\\t";
      else if(ch < 0x20)
         out += "\\u" + AgJsonHex4(ch);
      else
         out += ShortToString(ch);
     }
   return out;
  }

//+------------------------------------------------------------------+
//| A FLAT JSON READER. Every scalar of the document is listed with  |
//| its path: object keys joined by '.', array elements as [i], for  |
//| example result[0].message.chat.id. Strings are unescaped,        |
//| \uXXXX included, a surrogate pair arriving as its two halves;     |
//| numbers keep their text exactly as sent.                          |
//+------------------------------------------------------------------+
int AgJsonHexDigit(const ushort ch)
  {
   if(ch >= '0' && ch <= '9') return ch - '0';
   if(ch >= 'a' && ch <= 'f') return ch - 'a' + 10;
   if(ch >= 'A' && ch <= 'F') return ch - 'A' + 10;
   return -1;
  }

void AgJsonSkipWs(const string t, int &pos)
  {
   int len = StringLen(t);
   while(pos < len)
     {
      ushort ch = StringGetCharacter(t, pos);
      if(ch != ' ' && ch != '\t' && ch != '\n' && ch != '\r')
         break;
      pos++;
     }
  }

bool AgJsonString(const string t, int &pos, string &out)
  {
   int len = StringLen(t);
   out = "";
   if(pos >= len || StringGetCharacter(t, pos) != '"')
      return false;
   pos++;
   while(pos < len)
     {
      ushort ch = StringGetCharacter(t, pos);
      if(ch == '"')
        {
         pos++;
         return true;
        }
      if(ch == '\\')
        {
         pos++;
         if(pos >= len)
            return false;
         ushort e = StringGetCharacter(t, pos);
         if(e == '"')       out += "\"";
         else if(e == '\\') out += "\\";
         else if(e == '/')  out += "/";
         else if(e == 'b')  out += ShortToString(8);
         else if(e == 'f')  out += ShortToString(12);
         else if(e == 'n')  out += "\n";
         else if(e == 'r')  out += "\r";
         else if(e == 't')  out += "\t";
         else if(e == 'u')
           {
            if(pos + 4 >= len)
               return false;
            int v = 0;
            for(int k = 1; k <= 4; k++)
              {
               int d = AgJsonHexDigit(StringGetCharacter(t, pos + k));
               if(d < 0)
                  return false;
               v = v * 16 + d;
              }
            out += ShortToString((ushort)v);
            pos += 4;
           }
         else
            return false;
         pos++;
         continue;
        }
      if(ch < 0x20)
         return false;   // a raw control character is not valid JSON
      out += ShortToString(ch);
      pos++;
     }
   return false;
  }

void AgJsonAdd(string &paths[], string &values[], int &kinds[], int &count,
               const string path, const string value, const int kind)
  {
   ArrayResize(paths, count + 1);
   ArrayResize(values, count + 1);
   ArrayResize(kinds, count + 1);
   paths[count]  = path;
   values[count] = value;
   kinds[count]  = kind;
   count++;
  }

bool AgJsonValue(const string t, int &pos, const string path, string &paths[], string &values[],
                 int &kinds[], int &count, const int depth)
  {
   if(depth > AG_JSON_MAX_DEPTH)
      return false;
   int len = StringLen(t);
   AgJsonSkipWs(t, pos);
   if(pos >= len)
      return false;
   ushort ch = StringGetCharacter(t, pos);
   if(ch == '{')
     {
      pos++;
      AgJsonSkipWs(t, pos);
      if(pos < len && StringGetCharacter(t, pos) == '}')
        {
         pos++;
         return true;
        }
      while(true)
        {
         AgJsonSkipWs(t, pos);
         string key = "";
         if(!AgJsonString(t, pos, key))
            return false;
         AgJsonSkipWs(t, pos);
         if(pos >= len || StringGetCharacter(t, pos) != ':')
            return false;
         pos++;
         string sub = (path == "") ? key : (path + "." + key);
         if(!AgJsonValue(t, pos, sub, paths, values, kinds, count, depth + 1))
            return false;
         AgJsonSkipWs(t, pos);
         if(pos >= len)
            return false;
         ch = StringGetCharacter(t, pos);
         pos++;
         if(ch == ',')
            continue;
         if(ch == '}')
            return true;
         return false;
        }
     }
   if(ch == '[')
     {
      pos++;
      AgJsonSkipWs(t, pos);
      if(pos < len && StringGetCharacter(t, pos) == ']')
        {
         pos++;
         return true;
        }
      int index = 0;
      while(true)
        {
         string sub = path + "[" + (string)index + "]";
         if(!AgJsonValue(t, pos, sub, paths, values, kinds, count, depth + 1))
            return false;
         index++;
         AgJsonSkipWs(t, pos);
         if(pos >= len)
            return false;
         ch = StringGetCharacter(t, pos);
         pos++;
         if(ch == ',')
            continue;
         if(ch == ']')
            return true;
         return false;
        }
     }
   if(ch == '"')
     {
      string s = "";
      if(!AgJsonString(t, pos, s))
         return false;
      AgJsonAdd(paths, values, kinds, count, path, s, AG_JSON_STRING);
      return true;
     }
   if(StringSubstr(t, pos, 4) == "true")
     {
      pos += 4;
      AgJsonAdd(paths, values, kinds, count, path, "true", AG_JSON_TRUE);
      return true;
     }
   if(StringSubstr(t, pos, 5) == "false")
     {
      pos += 5;
      AgJsonAdd(paths, values, kinds, count, path, "false", AG_JSON_FALSE);
      return true;
     }
   if(StringSubstr(t, pos, 4) == "null")
     {
      pos += 4;
      AgJsonAdd(paths, values, kinds, count, path, "null", AG_JSON_NULL);
      return true;
     }
   //--- a number: [-] digits [. digits] [e [+-] digits]
   int start = pos;
   if(ch == '-')
      pos++;
   int digits = 0;
   while(pos < len && StringGetCharacter(t, pos) >= '0' && StringGetCharacter(t, pos) <= '9')
     {
      pos++;
      digits++;
     }
   if(digits == 0)
      return false;
   if(pos < len && StringGetCharacter(t, pos) == '.')
     {
      pos++;
      int frac = 0;
      while(pos < len && StringGetCharacter(t, pos) >= '0' && StringGetCharacter(t, pos) <= '9')
        {
         pos++;
         frac++;
        }
      if(frac == 0)
         return false;
     }
   if(pos < len && (StringGetCharacter(t, pos) == 'e' || StringGetCharacter(t, pos) == 'E'))
     {
      pos++;
      if(pos < len && (StringGetCharacter(t, pos) == '+' || StringGetCharacter(t, pos) == '-'))
         pos++;
      int exp = 0;
      while(pos < len && StringGetCharacter(t, pos) >= '0' && StringGetCharacter(t, pos) <= '9')
        {
         pos++;
         exp++;
        }
      if(exp == 0)
         return false;
     }
   AgJsonAdd(paths, values, kinds, count, path, StringSubstr(t, start, pos - start), AG_JSON_NUMBER);
   return true;
  }

//--- the whole document, nothing after it but whitespace
bool AgJsonParse(const string text, string &paths[], string &values[], int &kinds[], int &count)
  {
   count = 0;
   ArrayResize(paths, 0);
   ArrayResize(values, 0);
   ArrayResize(kinds, 0);
   int pos = 0;
   if(!AgJsonValue(text, pos, "", paths, values, kinds, count, 0))
      return false;
   AgJsonSkipWs(text, pos);
   return pos == StringLen(text);
  }

int AgJsonFind(const string &paths[], const int count, const string path)
  {
   for(int i = 0; i < count; i++)
      if(paths[i] == path)
         return i;
   return -1;
  }

//+------------------------------------------------------------------+
//| THE COMMAND, TG-8 (B), the exact match rule of addendum item 5.  |
//| One getUpdates answer, already decoded from UTF-8. An update     |
//| counts as the command only when all four hold: it carries        |
//| message (not edited_message, not channel_post, nothing else);    |
//| message.chat.id, as its decimal text, equals the configured chat |
//| id character for character; message.text, unescaped, equals the |
//| command exactly, with no trimming, normalizing or partial match; |
//| and message.date, UTC seconds, lies within max_age of now_gmt.    |
//| Returns the matches; ignored counts every other update. max_id   |
//| is the highest update_id seen, -1 when there is none. ok is false |
//| when the answer does not parse or does not read "ok":true.        |
//+------------------------------------------------------------------+
int AgTgMatchCommands(const string answer, const string command, const string chat_id,
                      const long now_gmt, const int max_age, long &max_id, int &ignored, bool &ok)
  {
   max_id  = -1;
   ignored = 0;
   ok      = false;
   string paths[];
   string values[];
   int    kinds[];
   int    count = 0;
   if(!AgJsonParse(answer, paths, values, kinds, count))
      return 0;
   int ok_at = AgJsonFind(paths, count, "ok");
   if(ok_at < 0 || kinds[ok_at] != AG_JSON_TRUE)
      return 0;
   ok = true;
   int matched = 0;
   for(int i = 0; i < 1000; i++)
     {
      string base = "result[" + (string)i + "]";
      int id_at = AgJsonFind(paths, count, base + ".update_id");
      if(id_at < 0)
         break;
      long update_id = StringToInteger(values[id_at]);
      if(update_id > max_id)
         max_id = update_id;
      int chat_at = AgJsonFind(paths, count, base + ".message.chat.id");
      int text_at = AgJsonFind(paths, count, base + ".message.text");
      int date_at = AgJsonFind(paths, count, base + ".message.date");
      bool is_match = (chat_at >= 0 && text_at >= 0 && date_at >= 0
                       && kinds[chat_at] == AG_JSON_NUMBER
                       && kinds[text_at] == AG_JSON_STRING
                       && kinds[date_at] == AG_JSON_NUMBER
                       && values[chat_at] == chat_id
                       && values[text_at] == command);
      if(is_match)
        {
         long date = StringToInteger(values[date_at]);
         is_match = (now_gmt - date <= max_age && date - now_gmt <= max_age);
        }
      if(is_match)
         matched++;
      else
         ignored++;
     }
   return matched;
  }

//--- parameters.retry_after of a 429 answer, 0 when absent
int AgTgRetryAfter(const string answer)
  {
   string paths[];
   string values[];
   int    kinds[];
   int    count = 0;
   if(!AgJsonParse(answer, paths, values, kinds, count))
      return 0;
   int at = AgJsonFind(paths, count, "parameters.retry_after");
   if(at < 0 || kinds[at] != AG_JSON_NUMBER)
      return 0;
   return (int)StringToInteger(values[at]);
  }

//+------------------------------------------------------------------+
//| THE THREE INPUTS (addendum 0.4). Pure checks; a caller never     |
//| prints the value, only the verdict.                              |
//+------------------------------------------------------------------+
bool AgTgCharIsDigit(const ushort ch) { return ch >= '0' && ch <= '9'; }

bool AgTgCharIsHex(const ushort ch) { return AgJsonHexDigit(ch) >= 0; }

//--- digits, a colon, then at least 30 letters, digits, underscores or hyphens
bool AgTgTokenValid(const string t)
  {
   int n = StringLen(t);
   int colon = StringFind(t, ":");
   if(colon < 1)
      return false;
   for(int i = 0; i < colon; i++)
      if(!AgTgCharIsDigit(StringGetCharacter(t, i)))
         return false;
   if(n - colon - 1 < 30)
      return false;
   for(int i = colon + 1; i < n; i++)
     {
      ushort ch = StringGetCharacter(t, i);
      bool good = AgTgCharIsDigit(ch) || (ch >= 'A' && ch <= 'Z') || (ch >= 'a' && ch <= 'z')
                  || ch == '_' || ch == '-';
      if(!good)
         return false;
     }
   return true;
  }

//--- an optional minus sign and 1 to 20 digits
bool AgTgChatIdValid(const string c)
  {
   int n = StringLen(c);
   int start = (n > 0 && StringGetCharacter(c, 0) == '-') ? 1 : 0;
   int digits = n - start;
   if(digits < 1 || digits > 20)
      return false;
   for(int i = start; i < n; i++)
      if(!AgTgCharIsDigit(StringGetCharacter(c, i)))
         return false;
   return true;
  }

//--- https://hc-ping.com/ and a UUID in the 8, 4, 4, 4, 12 shape
bool AgTgPingUrlValid(const string u)
  {
   string prefix = "https://hc-ping.com/";
   if(StringLen(u) != StringLen(prefix) + 36 || StringFind(u, prefix) != 0)
      return false;
   string id = StringSubstr(u, StringLen(prefix));
   for(int i = 0; i < 36; i++)
     {
      ushort ch = StringGetCharacter(id, i);
      bool dash_place = (i == 8 || i == 13 || i == 18 || i == 23);
      if(dash_place ? (ch != '-') : !AgTgCharIsHex(ch))
         return false;
     }
   return true;
  }

//--- how a channel reads on the start line: on, off:empty or off:malformed
string AgTgChannelState(const bool empty, const bool valid)
  {
   if(empty)
      return "off:empty";
   return valid ? "on" : "off:malformed";
  }

//+------------------------------------------------------------------+
//| THE STATUS SLOT, TG-15 (A) of 2026-10-21: the computer's local   |
//| clock, 00:00, 04:00, 08:00, 12:00, 16:00 and 20:00. The slot a   |
//| local instant falls in is its last 4 hour boundary from local    |
//| midnight; 86400 is a multiple of 14400, so the boundaries are    |
//| the same every day.                                              |
//+------------------------------------------------------------------+
#define AG_TG_STATUS_PERIOD_SECONDS 14400

long AgTgStatusSlot(const long local_t)
  {
   return local_t - (local_t % AG_TG_STATUS_PERIOD_SECONDS);
  }

//+------------------------------------------------------------------+
//| UTF-8, plan 6.5.1: StringToCharArray with CP_UTF8, the trailing  |
//| zero dropped, into the char array WebRequest takes; and back.    |
//+------------------------------------------------------------------+
int AgTgUtf8Bytes(const string s, char &out[])
  {
   uchar u[];
   int n = StringToCharArray(s, u, 0, WHOLE_ARRAY, CP_UTF8);
   if(n > 0 && u[n - 1] == 0)
      n--;
   ArrayResize(out, n);
   for(int i = 0; i < n; i++)
      out[i] = (char)u[i];
   return n;
  }

string AgTgUtf8ToString(const char &in[], const int n)
  {
   if(n <= 0)
      return "";
   uchar u[];
   ArrayResize(u, n);
   for(int i = 0; i < n; i++)
      u[i] = (uchar)in[i];
   return CharArrayToString(u, 0, n, CP_UTF8);
  }

#endif // AG_ALERT_JSON_MQH
