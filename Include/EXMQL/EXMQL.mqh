//+------------------------------------------------------------------+
//|                                                       EXMQL.mqh |
//|                                Copyright 2024, Yasuharu Kusumoto |
//|                                             https://www.mql5.com |
//|                                              Ver.alpha 2025/11/28
//+------------------------------------------------------------------+
#property copyright "Yasuharu Kusumoto"
#property link      "https://mqlinvestmentlab.com/"
#property strict

//+------------------------------------------------------------------+
#ifndef _EXMQL_
#define _EXMQL_

#include "errordescription.mqh"

//+------------------------------------------------------------------+
//|                                                   EXMQL_ENUM.mqh |
//|                                Copyright 2024, Yasuharu Kusumoto |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//| ロギングシステム用 Enum と 定数                                   |
//+------------------------------------------------------------------+
enum LOG_LEVEL 
{
    LOG_DEBUG,
    LOG_INFO,
    LOG_WARNING,
    LOG_ERROR,
    LOG_CRITICAL // 致命的なエラー（処理中断が必要なレベル）
};
// ログファイル名
#define EXMQL_LOG_FILE_NAME "EXMQL_System.log"

#ifdef __MQL5__
#define SYMBOL_USDJPY "USDJPY.ps01"
#else
#define SYMBOL_USDJPY "USDJPY"
#endif


#ifdef __MQL4__

enum ERR_CODE
  {
   ERR_SUCCESS = 0,        //操作が正常に完了しました。
//ERR_INTERNAL_ERROR=4001,
   ERR_WRONG_INTERNAL_PARAMETER = 4002,
   ERR_INVALID_PARAMETER = 4003,
   ERR_NOT_ENOUGH_MEMORY = 4004,
   ERR_STRUCT_WITHOBJECTS_ORCLASS = 4005,
   ERR_INVALID_ARRAY = 4006,
   ERR_ARRAY_RESIZE_ERROR = 4007,
   ERR_STRING_RESIZE_ERROR = 4008,
   ERR_NOTINITIALIZED_STRING = 4009,
   ERR_INVALID_DATETIME = 4010,
   ERR_ARRAY_BAD_SIZE = 4011,
//ERR_INVALID_POINTER=4012,
   ERR_INVALID_POINTER_TYPE = 4013,
   ERR_FUNCTION_NOT_ALLOWED = 4014,
   ERR_RESOURCE_NAME_DUPLICATED = 4015,
//ERR_RESOURCE_NOT_FOUND=4016,
   ERR_RESOURCE_UNSUPPORTED_TYPE = 4017,
   ERR_RESOURCE_NAME_IS_TOO_LONG = 4018,
   ERR_MATH_OVERFLOW = 4019,
   ERR_SLEEP_ERROR = 4020,
   ERR_PROGRAM_STOPPED = 4022,
   ERR_CHART_WRONG_ID = 4101,
   ERR_CHART_NO_REPLY = 4102,
//ERR_CHART_NOT_FOUND=4103,
   ERR_CHART_NO_EXPERT = 4104,
   ERR_CHART_CANNOT_OPEN = 4105,
   ERR_CHART_CANNOT_CHANGE = 4106,
   ERR_CHART_WRONG_PARAMETER = 4107,
   ERR_CHART_CANNOT_CREATE_TIMER = 4108,
   ERR_CHART_WRONG_PROPERTY = 4109,
   ERR_CHART_SCREENSHOT_FAILED = 4110,
   ERR_CHART_NAVIGATE_FAILED = 4111,
   ERR_CHART_TEMPLATE_FAILED = 4112,
   ERR_CHART_WINDOW_NOT_FOUND = 4113,
   ERR_CHART_INDICATOR_CANNOT_ADD = 4114,
   ERR_CHART_INDICATOR_CANNOT_DEL = 4115,
   ERR_CHART_INDICATOR_NOT_FOUND = 4116,
   ERR_OBJECT_ERROR = 4201,
   ERR_OBJECT_NOT_FOUND = 4202,
   ERR_OBJECT_WRONG_PROPERTY = 4203,
   ERR_OBJECT_GETDATE_FAILED = 4204,
   ERR_OBJECT_GETVALUE_FAILED = 4205,
   ERR_MARKET_UNKNOWN_SYMBOL = 4301,
   ERR_MARKET_NOT_SELECTED = 4302,
   ERR_MARKET_WRONG_PROPERTY = 4303,
   ERR_MARKET_LASTTIME_UNKNOWN = 4304,
   ERR_MARKET_SELECT_ERROR = 4305,
   ERR_HISTORY_NOT_FOUND = 4401,
   ERR_HISTORY_WRONG_PROPERTY = 4402,
   ERR_HISTORY_TIMEOUT = 4403,
   ERR_HISTORY_BARS_LIMIT = 4404,
   ERR_HISTORY_LOAD_ERRORS = 4405,
   ERR_HISTORY_SMALL_BUFFER = 4407,
   ERR_GLOBALVARIABLE_NOT_FOUND = 4501,
   ERR_GLOBALVARIABLE_EXISTS = 4502,
   ERR_GLOBALVARIABLE_NOT_MODIFIED = 4503,
   ERR_GLOBALVARIABLE_CANNOTREAD = 4504,
   ERR_GLOBALVARIABLE_CANNOTWRITE = 4505,
   ERR_MAIL_SEND_FAILED = 4510,
   ERR_PLAY_SOUND_FAILED = 4511,
   ERR_MQL5_WRONG_PROPERTY = 4512,
   ERR_TERMINAL_WRONG_PROPERTY = 4513,
   ERR_FTP_SEND_FAILED = 4514,
   ERR_NOTIFICATION_SEND_FAILED = 4515,
   ERR_NOTIFICATION_WRONG_PARAMETER = 4516,
   ERR_NOTIFICATION_WRONG_SETTINGS = 4517,
//ERR_NOTIFICATION_TOO_FREQUENT=4518,
//ERR_FTP_NOSERVER=4519,
//ERR_FTP_NOLOGIN=4520,
//ERR_FTP_FILE_ERROR=4521,
//ERR_FTP_CONNECT_FAILED=4522,
//ERR_FTP_CHANGEDIR=4523,
   ERR_BUFFERS_NO_MEMORY = 4601,
   ERR_BUFFERS_WRONG_INDEX = 4602,
   ERR_CUSTOM_WRONG_PROPERTY = 4603,
   ERR_ACCOUNT_WRONG_PROPERTY = 4701,
   ERR_TRADE_WRONG_PROPERTY = 4751,
//ERR_TRADE_DISABLED=4752,
   ERR_TRADE_POSITION_NOT_FOUND = 4753,
   ERR_TRADE_ORDER_NOT_FOUND = 4754,
   ERR_TRADE_DEAL_NOT_FOUND = 4755,
   ERR_TRADE_SEND_FAILED = 4756,
   ERR_TRADE_CALC_FAILED = 4758,
   ERR_INDICATOR_UNKNOWN_SYMBOL = 4801,
   ERR_INDICATOR_CANNOT_CREATE = 4802,
   ERR_INDICATOR_NO_MEMORY = 4803,
   ERR_INDICATOR_CANNOT_APPLY = 4804,
   ERR_INDICATOR_CANNOT_ADD = 4805,
   ERR_INDICATOR_DATA_NOT_FOUND = 4806,
   ERR_INDICATOR_WRONG_HANDLE = 4807,
   ERR_INDICATOR_WRONG_PARAMETERS = 4808,
   ERR_INDICATOR_PARAMETERS_MISSING = 4809,
   ERR_INDICATOR_CUSTOM_NAME = 4810,
   ERR_INDICATOR_PARAMETER_TYPE = 4811,
   ERR_INDICATOR_WRONG_INDEX = 4812,
   ERR_BOOKS_CANNOT_ADD = 4901,
   ERR_BOOKS_CANNOT_DELETE = 4902,
   ERR_BOOKS_CANNOT_GET = 4903,
   ERR_BOOKS_CANNOT_SUBSCRIBE = 4904,
   ERR_TOO_MANY_FILES = 5001,
   ERR_WRONG_FILENAME = 5002,
   ERR_TOO_LONG_FILENAME = 5003,
//ERR_CANNOT_OPEN_FILE=5004,
   ERR_FILE_CACHEBUFFER_ERROR = 5005,
   ERR_CANNOT_DELETE_FILE = 5006,
   ERR_INVALID_FILEHANDLE = 5007,
   ERR_WRONG_FILEHANDLE = 5008,
   ERR_FILE_NOTTOWRITE = 5009,
   ERR_FILE_NOTTOREAD = 5010,
   ERR_FILE_NOTBIN = 5011,
   ERR_FILE_NOTTXT = 5012,
   ERR_FILE_NOTTXTORCSV = 5013,
   ERR_FILE_NOTCSV = 5014,
   ERR_FILE_READERROR = 5015,
   ERR_FILE_BINSTRINGSIZE = 5016,
   ERR_INCOMPATIBLE_FILE = 5017,
//ERR_FILE_IS_DIRECTORY=5018,
//ERR_FILE_NOT_EXIST=5019,
//ERR_FILE_CANNOT_REWRITE=5020,
//-------------//ERR_WRONG_DIRECTORYNAME=5021
   ERR_WRONG_DIRECTORYNAME = 65021,
   ERR_DIRECTORY_NOT_EXIST = 5022,
   ERR_FILE_ISNOT_DIRECTORY = 5023,
   ERR_CANNOT_DELETE_DIRECTORY = 5024,
   ERR_CANNOT_CLEAN_DIRECTORY = 5025,
   ERR_FILE_WRITEERROR = 5026,
   ERR_FILE_ENDOFFILE = 5027,
   ERR_NO_STRING_DATE = 5030,
   ERR_WRONG_STRING_DATE = 5031,
   ERR_WRONG_STRING_TIME = 5032,
   ERR_STRING_TIME_ERROR = 5033,
   ERR_STRING_OUT_OF_MEMORY = 5034,
   ERR_STRING_SMALL_LEN = 5035,
   ERR_STRING_TOO_BIGNUMBER = 5036,
   ERR_WRONG_FORMATSTRING = 5037,
   ERR_TOO_MANY_FORMATTERS = 5038,
   ERR_TOO_MANY_PARAMETERS = 5039,
   ERR_WRONG_STRING_PARAMETER = 5040,
   ERR_STRINGPOS_OUTOFRANGE = 5041,
   ERR_STRING_ZEROADDED = 5042,
   ERR_STRING_UNKNOWNTYPE = 5043,
   ERR_WRONG_STRING_OBJECT = 5044,
//ERR_INCOMPATIBLE_ARRAYS=5050,
   ERR_SMALL_ASSERIES_ARRAY = 5051,
   ERR_SMALL_ARRAY = 5052,
   ERR_ZEROSIZE_ARRAY = 5053,
   ERR_NUMBER_ARRAYS_ONLY = 5054,
   ERR_ONEDIM_ARRAYS_ONLY = 5055,
   ERR_SERIES_ARRAY = 5056,
   ERR_DOUBLE_ARRAY_ONLY = 5057,
   ERR_FLOAT_ARRAY_ONLY = 5058,
   ERR_LONG_ARRAY_ONLY = 5059,
   ERR_INT_ARRAY_ONLY = 5060,
   ERR_SHORT_ARRAY_ONLY = 5061,
   ERR_CHAR_ARRAY_ONLY = 5062,
   ERR_STRING_ARRAY_ONLY = 5063,
   ERR_OPENCL_NOT_SUPPORTED = 5100,
   ERR_OPENCL_INTERNAL = 5101,
   ERR_OPENCL_INVALID_HANDLE = 5102,
   ERR_OPENCL_CONTEXT_CREATE = 5103,
   ERR_OPENCL_QUEUE_CREATE = 5104,
   ERR_OPENCL_PROGRAM_CREATE = 5105,
   ERR_OPENCL_TOO_LONG_KERNEL_NAME = 5106,
   ERR_OPENCL_KERNEL_CREATE = 5107,
   ERR_OPENCL_SET_KERNEL_PARAMETER = 5108,
   ERR_OPENCL_EXECUTE = 5109,
   ERR_OPENCL_WRONG_BUFFER_SIZE = 5110,
   ERR_OPENCL_WRONG_BUFFER_OFFSET = 5111,
   ERR_OPENCL_BUFFER_CREATE = 5112,
   ERR_OPENCL_TOO_MANY_OBJECTS = 5113,
   ERR_OPENCL_SELECTDEVICE = 5114,
   ERR_DATABASE_INTERNAL = 5120,
   ERR_DATABASE_INVALID_HANDLE = 5121,
   ERR_DATABASE_TOO_MANY_OBJECTS = 5122,
   ERR_DATABASE_CONNECT = 5123,
   ERR_DATABASE_EXECUTE = 5124,
   ERR_DATABASE_PREPARE = 5125,
   ERR_DATABASE_NO_MORE_DATA = 5126,
   ERR_DATABASE_STEP = 5127,
   ERR_DATABASE_NOT_READY = 5128,
   ERR_DATABASE_BIND_PARAMETERS = 5129,
//ERR_WEBREQUEST_INVALID_ADDRESS=5200,
//ERR_WEBREQUEST_CONNECT_FAILED=5201,
//ERR_WEBREQUEST_TIMEOUT=5202,
//ERR_WEBREQUEST_REQUEST_FAILED=5203,
   ERR_NETSOCKET_INVALIDHANDLE = 5270,
   ERR_NETSOCKET_TOO_MANY_OPENED = 5271,
   ERR_NETSOCKET_CANNOT_CONNECT = 5272,
   ERR_NETSOCKET_IO_ERROR = 5273,
   ERR_NETSOCKET_HANDSHAKE_FAILED = 5274,
   ERR_NETSOCKET_NO_CERTIFICATE = 5275,
   ERR_NOT_CUSTOM_SYMBOL = 5300,
   ERR_CUSTOM_SYMBOL_WRONG_NAME = 5301,
   ERR_CUSTOM_SYMBOL_NAME_LONG = 5302,
   ERR_CUSTOM_SYMBOL_PATH_LONG = 5303,
   ERR_CUSTOM_SYMBOL_EXIST = 5304,
   ERR_CUSTOM_SYMBOL_ERROR = 5305,
   ERR_CUSTOM_SYMBOL_SELECTED = 5306,
   ERR_CUSTOM_SYMBOL_PROPERTY_WRONG = 5307,
   ERR_CUSTOM_SYMBOL_PARAMETER_ERROR = 5308,
   ERR_CUSTOM_SYMBOL_PARAMETER_LONG = 5309,
   ERR_CUSTOM_TICKS_WRONG_ORDER = 5310,
   ERR_CALENDAR_MORE_DATA = 5400,
   ERR_CALENDAR_TIMEOUT = 5401,
   ERR_CALENDAR_NO_DATA = 5402,
   ERR_DATABASE_ERROR = 5601,
   ERR_DATABASE_LOGIC = 5602,
   ERR_DATABASE_PERM = 5603,
   ERR_DATABASE_ABORT = 5604,
   ERR_DATABASE_BUSY = 5605,
   ERR_DATABASE_LOCKED = 5606,
   ERR_DATABASE_NOMEM = 5607,
   ERR_DATABASE_READONLY = 5608,
   ERR_DATABASE_INTERRUPT = 5609,
   ERR_DATABASE_IOERR = 5610,
   ERR_DATABASE_CORRUPT = 5611,
   ERR_DATABASE_NOTFOUND = 5612,
   ERR_DATABASE_FULL = 5613,
   ERR_DATABASE_CANTOPEN = 5614,
   ERR_DATABASE_PROTOCOL = 5615,
   ERR_DATABASE_EMPTY = 5616,
   ERR_DATABASE_SCHEMA = 5617,
   ERR_DATABASE_TOOBIG = 5618,
   ERR_DATABASE_CONSTRAINT = 5619,
   ERR_DATABASE_MISMATCH = 5620,
   ERR_DATABASE_MISUSE = 5621,
   ERR_DATABASE_NOLFS = 5622,
   ERR_DATABASE_AUTH = 5623,
   ERR_DATABASE_FORMAT = 5624,
   ERR_DATABASE_RANGE = 5625,
   ERR_DATABASE_NOTADB = 5626,
//ERR_USER_ERROR_FIRST=65536
   ERR_USER_ERROR_LAST = 65537
  };


enum ENUM_ORDER_PROPERTY_INTEGER_MQL5
  {
   ORDER_TICKET,
   ORDER_REASON,
   ORDER_POSITION_ID,
   ORDER_POSITION_BY_ID
  };


enum ENUM_ORDER_TYPE_MQL5
  {
   ORDER_TYPE_BUY_STOP_LIMIT = 6,
   ORDER_TYPE_SELL_STOP_LIMIT = 7,
   ORDER_TYPE_CLOSE_BY = 8
  };


enum ENUM_ORDER_STATE
  {
   ORDER_STATE_STARTED,
   ORDER_STATE_PLACED,
   ORDER_STATE_CANCELED,
   ORDER_STATE_PARTIAL,
   ORDER_STATE_FILLED,
   ORDER_STATE_REJECTED,
   ORDER_STATE_EXPIRED,
   ORDER_STATE_REQUEST_ADD,
   ORDER_STATE_REQUEST_MODIFY,
   ORDER_STATE_REQUEST_CANCEL
  };


enum ENUM_ORDER_TYPE_TIME
  {
   ORDER_TIME_GTC,
   ORDER_TIME_DAY,
   ORDER_TIME_SPECIFIED,
   ORDER_TIME_SPECIFIED_DAY
  };


enum ENUM_ORDER_REASON
  {
   ORDER_REASON_CLIENT,
   ORDER_REASON_MOBILE,
   ORDER_REASON_WEB,
   ORDER_REASON_EXPERT,
   ORDER_REASON_SL,
   ORDER_REASON_TP,
   ORDER_REASON_SO
  };


enum ENUM_POSITION_PROPERTY_INTEGER
  {
   POSITION_TICKET,
   POSITION_TIME,
   POSITION_TIME_MSC,
   POSITION_TIME_UPDATE,
   POSITION_TIME_UPDATE_MSC,
   POSITION_TYPE,
   POSITION_MAGIC,
   POSITION_IDENTIFIER,
   POSITION_REASON
  };

enum ENUM_POSITION_PROPERTY_DOUBLE
  {
   POSITION_VOLUME,
   POSITION_PRICE_OPEN,
   POSITION_SL,
   POSITION_TP,
   POSITION_PRICE_CURRENT,
   POSITION_SWAP,
   POSITION_PROFIT
  };

enum ENUM_POSITION_PROPERTY_STRING
  {
   POSITION_SYMBOL,
   POSITION_COMMENT,
   POSITION_EXTERNAL_ID
  };

enum ENUM_POSITION_TYPE
  {
   POSITION_TYPE_BUY,
   POSITION_TYPE_SELL
  };

enum ENUM_POSITION_REASON
  {
   POSITION_REASON_CLIENT,
   POSITION_REASON_MOBILE,
   POSITION_REASON_WEB,
   POSITION_REASON_EXPERT
  };

enum ENUM_ACCOUNT_INFO_INTEGER_EXMQL
  {
   ACCOUNT_MARGIN_MODE,
   ACCOUNT_CURRENCY_DIGITS,
   ACCOUNT_FIFO_CLOSE
  };

enum ENUM_ACCOUNT_MARGIN_MODE
  {
   ACCOUNT_MARGIN_MODE_RETAIL_NETTING,
   ACCOUNT_MARGIN_MODE_EXCHANGE,
   ACCOUNT_MARGIN_MODE_RETAIL_HEDGING
  };

enum ENUM_APPLIED_VOLUME
  {
   VOLUME_TICK,   //ティックボリューム。
   VOLUME_REAL    //取引高。
  };

enum ENUM_SYMBOL_INFO_INTEGER_EXMQL
  {
   SYMBOL_SECTOR,
   SYMBOL_INDUSTRY,
   SYMBOL_CUSTOM,
   SYMBOL_BACKGROUND_COLOR,
   SYMBOL_CHART_MODE,
   SYMBOL_EXIST,
   SYMBOL_TIME_MSC,
   SYMBOL_MARGIN_HEDGED_USE_LEG,
   SYMBOL_ORDER_GTC_MODE,
   SYMBOL_OPTION_MODE,
   SYMBOL_OPTION_RIGHT
  };

enum ENUM_SYMBOL_INFO_DOUBLE_EXMQL
  {
   SYMBOL_VOLUME_REAL,
   SYMBOL_VOLUMEHIGH_REAL,
   SYMBOL_VOLUMELOW_REAL,
   SYMBOL_OPTION_STRIKE,
   SYMBOL_TRADE_ACCRUED_INTEREST,
   SYMBOL_TRADE_FACE_VALUE,
   SYMBOL_TRADE_LIQUIDITY_RATE,
   SYMBOL_SWAP_SUNDAY,
   SYMBOL_SWAP_MONDAY,
   SYMBOL_SWAP_TUESDAY,
   SYMBOL_SWAP_WEDNESDAY,
   SYMBOL_SWAP_THURSDAY,
   SYMBOL_SWAP_FRIDAY,
   SYMBOL_SWAP_SATURDAY,
   SYMBOL_MARGIN_HEDGED,
   SYMBOL_PRICE_CHANGE,
   SYMBOL_PRICE_VOLATILITY,
   SYMBOL_PRICE_THEORETICAL,
   SYMBOL_PRICE_DELTA,
   SYMBOL_PRICE_THETA,
   SYMBOL_PRICE_GAMMA,
   SYMBOL_PRICE_VEGA,
   SYMBOL_PRICE_RHO,
   SYMBOL_PRICE_OMEGA,
   SYMBOL_PRICE_SENSITIVITY
  };

enum ENUM_SYMBOL_INFO_STRING_EXMQL
  {
   SYMBOL_BASIS,
   SYMBOL_CATEGORY,
   SYMBOL_COUNTRY,
   SYMBOL_SECTOR_NAME,
   SYMBOL_INDUSTRY_NAME,
   SYMBOL_EXCHANGE,
   SYMBOL_FORMULA,
   SYMBOL_PAGE
  };

enum ENUM_SYMBOL_CHART_MODE
  {
   SYMBOL_CHART_MODE_BID,
   SYMBOL_CHART_MODE_LAST
  };

enum ENUM_SYMBOL_EXPIRATION
  {
   SYMBOL_EXPIRATION_GTC = 1,
   SYMBOL_EXPIRATION_DAY = 2,
   SYMBOL_EXPIRATION_SPECIFIED = 4,
   SYMBOL_EXPIRATION_SPECIFIED_DAY = 8
  };

enum ENUM_SYMBOL_ORDER_GTC_MODE
  {
   SYMBOL_ORDERS_GTC,
   SYMBOL_ORDERS_DAILY,
   SYMBOL_ORDERS_DAILY_EXCLUDING_STOPS
  };

enum ENUM_SYMBOL_FILLING
  {
   SYMBOL_FILLING_FOK = 1,
   SYMBOL_FILLING_IOC = 2,
   SYMBOL_FILLING_BOC = 4,
   SYMBOL_FILLING_RTN = 0
  };

enum ENUM_TRADE_REQUEST_ACTIONS
  {
   TRADE_ACTION_DEAL,
   TRADE_ACTION_PENDING,
   TRADE_ACTION_SLTP,
   TRADE_ACTION_MODIFY,
   TRADE_ACTION_REMOVE,
   TRADE_ACTION_CLOSE_BY
  };

enum ENUM_ORDER_TYPE_FILLING
  {
   ORDER_FILLING_FOK,
   ORDER_FILLING_IOC,
   ORDER_FILLING_BOC,
   ORDER_FILLING_RETURN
  };




enum ENUM_TRADE_RETCODE
  {
   TRADE_RETCODE_REQUOTE = 10004, //リクオート。
   TRADE_RETCODE_REJECT = 10006, //リクエストの拒否。
   TRADE_RETCODE_CANCEL = 10007, //トレーダーによるリクエストのキャンセル。
   TRADE_RETCODE_PLACED = 10008, //注文が出されました。
   TRADE_RETCODE_DONE = 10009, //リクエスト完了。
   TRADE_RETCODE_DONE_PARTIAL = 10010, //リクエストが一部のみ完了。
   TRADE_RETCODE_ERROR = 10011, //リクエスト処理エラー。
   TRADE_RETCODE_TIMEOUT = 10012, //リクエストが時間切れでキャンセル。
   TRADE_RETCODE_INVALID = 10013, //無効なリクエスト。
   TRADE_RETCODE_INVALID_VOLUME = 10014, //リクエスト内の無効なボリューム。
   TRADE_RETCODE_INVALID_PRICE = 10015, //リクエスト内の無効な価格。
   TRADE_RETCODE_INVALID_STOPS = 10016, //リクエスト内の無効なストップ。
   TRADE_RETCODE_TRADE_DISABLED = 10017, //取引が無効化されています。
   TRADE_RETCODE_MARKET_CLOSED = 10018, //市場が閉鎖中。
   TRADE_RETCODE_NO_MONEY = 10019, //リクエストを完了するのに資金が不充分。
   TRADE_RETCODE_PRICE_CHANGED = 10020, //価格変更。
   TRADE_RETCODE_PRICE_OFF = 10021, //リクエスト処理に必要な相場が不在。
   TRADE_RETCODE_INVALID_EXPIRATION = 10022, //リクエスト内の無効な注文有効期限。
   TRADE_RETCODE_ORDER_CHANGED = 10023, //注文状態の変化。
   TRADE_RETCODE_TOO_MANY_REQUESTS = 10024, //頻繁過ぎるリクエスト。
   TRADE_RETCODE_NO_CHANGES = 10025, //リクエストに変更なし。
   TRADE_RETCODE_SERVER_DISABLES_AT = 10026, //サーバが自動取引を無効化。
   TRADE_RETCODE_CLIENT_DISABLES_AT = 10027, //クライアント端末が自動取引を無効化。
   TRADE_RETCODE_LOCKED = 10028, //リクエストが処理のためにロック中。
   TRADE_RETCODE_FROZEN = 10029, //注文やポジションが凍結。
   TRADE_RETCODE_INVALID_FILL = 10030, //無効な注文充填タイプ。
   TRADE_RETCODE_CONNECTION = 10031, //取引サーバに未接続。
   TRADE_RETCODE_ONLY_REAL = 10032, //操作は、ライブ口座のみで許可。
   TRADE_RETCODE_LIMIT_ORDERS = 10033, //未決注文の数が上限に達しました。
   TRADE_RETCODE_LIMIT_VOLUME = 10034, //シンボルの注文やポジションのボリュームが限界に達しました。
   TRADE_RETCODE_INVALID_ORDER = 10035, //不正または禁止された注文の種類。
   TRADE_RETCODE_POSITION_CLOSED = 10036, //指定されたPOSITION_IDENTIFIER を持つポジションがすでに閉鎖。
   TRADE_RETCODE_INVALID_CLOSE_VOLUME = 10038, //決済ボリュームが現在のポジションのボリュームを超過。
   TRADE_RETCODE_CLOSE_ORDER_EXIST = 10039,  //指定されたポジションの決済注文が既存。これは、ヘッジシステムでの作業中に発生する可能性があります。
//反対のポジションを決済しようとしているときにそのポジションの決済注文が既に存在している場合
//ポジションを完全または部分的に決済しようとしているときに既存する決済注文と新しく出された決済注文の合計が現在のポジションボリュームを超えている場合
   TRADE_RETCODE_LIMIT_POSITIONS = 10040, //アカウントに同時に存在するポジションの数は、サーバー設定によって制限されます。 限度に達すると、サーバーは出された注文を処理するときにTRADE_RETCODE_LIMIT_POSITIONSエラーを返します。 これは、ポジション会計タイプによって異なる動作につながります。
//ネッティング - ポジションの数が考慮されます。 限度に達すると、プラットフォームはその実行によってポジションの数が増加する可能性がある新しい注文の発注を無効にします。 実際には、プラットホームは、既にポジションを有する銘柄についてのみの発注を可能にします。 現在の未決注文は、実行によって現在のポジションの変更につながる可能性がありますがその数を増やすことはできないので考慮されません。
//ヘッジング - 未決注文のアクティブ化によって常に新しいポジションが開かれるため、未決注文はポジションとともに考慮されます。限度に達すると、プラットフォームは、成行注文と未決注文の両方での新しい発注を無効にします。
   TRADE_RETCODE_REJECT_CANCEL = 10041, //未決注文アクティベーションリクエストは却下され、注文はキャンセルされます。
   TRADE_RETCODE_LONG_ONLY = 10042, //銘柄に"Only long positions are allowed（買いポジションのみ）" (POSITION_TYPE_BUY)のルールが設定されているため、リクエストは却下されます。
   TRADE_RETCODE_SHORT_ONLY = 10043, //銘柄に"Only short positions are allowed（売りポジションのみ）" (POSITION_TYPE_SELL)のルールが設定されているため、リクエストは却下されます。
   TRADE_RETCODE_CLOSE_ONLY = 10044, //銘柄に"Only position closing is allowed（ポジション決済のみ）"のルールが設定されているため、リクエストは却下されます。
   TRADE_RETCODE_FIFO_CLOSE = 10045, //取引口座に"Position closing is allowed only by FIFO rule（FIFOによるポジション決済のみ）"(ACCOUNT_FIFO_CLOSE=true)のフラグが設定されているため、リクエストは却下されます
   TRADE_RETCODE_HEDGE_PROHIBITED = 10046, //口座で「単一の銘柄の反対のポジションは無効にする」ルールが設定されているため、リクエストが拒否されます。たとえば、銘柄に買いポジションがある場合、売りポジションを開いたり、売り指値注文を出すことはできません。このルールは口座がヘッジ勘定の場合 (ACCOUNT_MARGIN_MODE=ACCOUNT_MARGIN_MODE_RETAIL_HEDGING)のみ適用されます。
  };


enum ENUM_TECHNICAL_INDICATOR_TYPE
  {
   T_iAC,         //ACオシレーター。
   T_iAD,         //蓄積/配信（Accumulation/Distribution）。
   T_iADX,        //平均方向性指数（Average Directional Index）。
   T_iADXWilder,  //ウェルズワイルダーの平均方向性指数（Average Directional Index by Welles Wilder）
   T_iAlligator,  //アリゲーター。
   T_iAMA,        //適応型移動平均（Adaptive Moving Average）。
   T_iAO,         //オーサムオシレーター。
   T_iATR,        //ATR（Average True Range）。
   T_iBearsPower, //ベアパワー（Bears Power）。
   T_iBands,      //ボリンジャーバンドR（Bollinger BandsR）。
   T_iBullsPower, //ブルパワー（Bulls Power）。
   T_iCCI,        //コモディティチャンネルインデックス（Commodity Channel Index）。
   T_iChaikin,    //チャイキンオシレーター（Chaikin Oscillator）。
   T_iCustom,     //カスタム指標。
   T_iDEMA,       //2 重指数移動平均（Double Exponential Moving Average）。
   T_iDeMarker,   //デマーカー（DeMarker）。
   T_iEnvelopes,  //エンベローブ（Envelopes）。
   T_iForce,      //勢力指数（Force Index）。
   T_iFractals,   //フラクタル。
   T_iFrAMA,      //フラクタル適応型移動平均（Fractal Adaptive Moving Average）。
   T_iGator,      //ゲーターオシレーター。
   T_iIchimoku,   //一目均衡表（Ichimoku Kinko Hyo）。
   T_iBWMFI,      //ビル・ウィリアムズのマーケットファシリテーションインデックス
   T_iMomentum,   //モメンタム（Momentum）。
   T_iMFI,        //マネーフローインデックス（Money Flow Index）。
   T_iMA,         //移動平均（Moving Average）。
   T_iOsMA,       //移動平均オシレーター（Moving Average of Oscillator）（MACD ヒストグラム）。
   T_iMACD,       //移動平均収束拡散法（Moving Averages Convergence-Divergence）
   T_iOBV,        //オンバランスボリューム（On Balance Volume）。
   T_iSAR,        //パラボリック停止・リバースシステム（Parabolic Stop And Reverse System）
   T_iRSI,        //相対力指数（Relative Strength Index）。
   T_iRVI,        //相対活力指数（Relative Vigor Index）。
   T_iStdDev,     //標準偏差（Standard Deviation）。
   T_iStochastic, //ストキャスティックス（Stochastic Oscillator）。
   T_iTEMA,       //3 重指数移動平均（Triple Exponential Moving Average）。
   T_iTriX,       //3 重指数移動平均オシレーター（Triple Exponential Moving Averages Oscillator）。
   T_iWPR,        //ウィリアムパーセントレンジ（Williams' Percent Range）。
   T_iVIDyA,      //可変インデックス動的平均（Variable Index Dynamic Average）。
   T_iVolumes     //ボリューム。
  };
  

//+------------------------------------------------------------------+
//             struct
//+------------------------------------------------------------------+

struct MqlTradeRequest
  {
   ENUM_TRADE_REQUEST_ACTIONS   action;           // 取引の種類
   ulong                         magic;           // エキスパートアドバイザー ID（マジックナンバー）
   ulong                         order;           // 注文チケット
   string                       symbol;           // 取引シンボル
   double                       volume;           // 約定のための要求されたボリューム（ロット単位）
   double                       price;           // 価格
   double                       stoplimit;       // 注文のストップリミットレベル
   double                       sl;               // 注文の決済逆指値レベル
   double                       tp;               // 注文の決済指値レベル
   ulong                         deviation;       // リクエストされた価格からの可能な最大偏差
   ENUM_ORDER_TYPE               type;             // 注文の種類
   ENUM_ORDER_TYPE_FILLING       type_filling;     // 注文実行の種類
   ENUM_ORDER_TYPE_TIME        type_time;       // 注文期限切れの種類
   datetime                     expiration;       // 注文期限切れの時刻 （ORDER_TIME_SPECIFIED 型の注文）
   string                       comment;         // 注文コメント
   ulong                         position;         // Position ticket
   ulong                         position_by;     // The ticket of an opposite position
  };

struct MqlTradeResult
  {
   uint              retcode;         // 操作のリターンコード
   ulong             deal;             // 実行された場合の 約定チケット
   ulong             order;           // 注文された場合のチケット
   double            volume;           // ブローカーによって確認された約定ボリューム
   double            price;           // ブローカーによって確認された約定価格
   double            bid;             // 現在の売値
   double            ask;             // 現在の買値
   string            comment;         // 操作に対するブローカーコメント（デフォルトは取引サーバの返したコードの記述）
   uint              request_id;       // ディスパッチの際に、端末によって設定されたリクエストID
   uint              retcode_external; // 外部取引システムのリターンコード
  };



//// 履歴ファイル名
//#define SIGNAL_HISTORY_FILE_NAME "CEnvironment_Signals.csv"

// 履歴構造体
struct MqlSignalResult
{
    ulong              signal_id;        
    datetime           time;             
    long               position_ticket;  
    ENUM_SIGNAL_TYPE   signal_type;      
    double             profit;           
    long               duration_sec;     
};


template<typename t_para>
class CPara
  {
public:
   CPara &           operator= (CPara &para)
     {
      m_para = para;
      return *this;
     }
   t_para &          operator= (CPara &para)
     {
      CPara OldValue;
      OldValue.m_para = m_para;
      m_para = para
               return OldValue
     }
private:
   t_para            m_para;
  };

struct MqlTechnicalIndicatorsHandle
  {
   bool                          bValid;           //有効／無効
   ENUM_TECHNICAL_INDICATOR_TYPE type;             // テクニカル指標タイプ
   string                        symbol;           // 銘柄名
   ENUM_TIMEFRAMES               period;           // 期間
   ENUM_APPLIED_VOLUME           applied_volume;   // 計算に使用するボリュームの種類
   ENUM_MA_METHOD                ma_method;        // 平滑化の種類
   int                           ama_period;       // AMA 平均期間
   int                           bands_period;     // 平均線の計算の期間
   int                           jaw_period;       // 顎の計算期間
   int                           lips_period;      // 口の計算期間
   int                           ma_period;        // 平均期間
   int                           teeth_period;     // 歯の計算期間
   int                           adx_period;       // 平均期間
   int                           calc_period;      // 平均期間
   int                           cmo_period;       // Chandeモメンタムの期間 Momentum
   int                           ema_period;       // EMA 平滑期間
   int                           fast_ma_period;   // 高速 MA 期間
   int                           mom_period;       // 平均期間
   int                           slow_ma_period;   // 低速 MA 期間
   int                           Dperiod;          // D期間（初めの平滑化の期間）
   int                           Kperiod;          // K期間（計算に使用されるバーの数）
   int                           ama_shift;        // 指標の水平シフト
   int                           bands_shift;      // 指標の水平シフト
   int                           jaw_shift;        // 顎の水平シフト
   int                           lips_shift;       // 口の水平シフト
   int                           ma_shift;         // 価格チャートでの水平シフト
   int                           teeth_shift;      // 歯の水平シフト
   int                           tenkan_sen;       // 転換線の期間
   int                           kijun_sen;        // 基準線の期間
   int                           senkou_span_b;    // 先行スパンＢの期間
   int                           slowing;          // 最終の平滑化
   int                           mode;             // モード
   double                        deviation;        // 標準偏差の数
   double                        step;             // 価格増分ステップ（加速因子）
   double                        maximum;          // ステップの最大値
   string                        name;             // フォルダ/カスタム指標名
   ENUM_STO_PRICE                price_field;      // 確率論的計算方法
   ENUM_APPLIED_PRICE            applied_price;    // 価格の種類かハンドル

   //GMMA
   ENUM_TIMEFRAMES      tf_para1;
   ENUM_APPLIED_PRICE   tf_para2;
   ENUM_MA_METHOD       ap_para3;
  };

#endif

//--------------------------------------------------------------------

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class exLOG
  {
public:
                     exLOG() {};
                    ~exLOG() {};
   void              Print(string message)
     {
      Print(message);
     };
   void              Out(MqlTradeRequest &req,MqlTradeResult &res)
     {
      //Print("Req.act:",req.action,           // 取引の種類
      //		" mgc:",req.magic,           // エキスパートアドバイザー ID（マジックナンバー）
      //		" odr:",req.order,           // 注文チケット
      //		" sym:",req.symbol,           // 取引シンボル
      //		" vol:",req.volume,           // 約定のための要求されたボリューム（ロット単位）
      //		" prc:",req.price,           // 価格
      //		" stl:",req.stoplimit,       // 注文のストップリミットレベル
      //		" sl :",req.sl,               // 注文の決済逆指値レベル
      //		" tp :",req.tp,               // 注文の決済指値レベル
      //		" dev:",req.deviation,       // リクエストされた価格からの可能な最大偏差
      //		" typ:",req.type,             // 注文の種類
      //		" tyf:",req.type_filling,     // 注文実行の種類
      //		" tyt:",req.type_time,       // 注文期限切れの種類
      //		" exp:",req.expiration,       // 注文期限切れの時刻 （ORDER_TIME_SPECIFIED 型の注文）
      //		" com:",req.comment,         // 注文コメント
      //		" pos:",req.position,         // Position ticket
      //		" pob:",req.position_by,"_");     // The ticket of an opposite position
      //Print(	"Res.ret:",res.retcode,         // 操作のリターンコード
      //		"del:",res.deal,             // 実行された場合の 約定チケット
      //		"ord:",res.order,           // 注文された場合のチケット
      //		"vol:",res.volume,           // ブローカーによって確認された約定ボリューム
      //		"prc:",res.price,           // ブローカーによって確認された約定価格
      //		"bid:",res.bid,             // 現在の売値
      //		"ask:",res.ask,             // 現在の買値
      //		"com:",res.comment,         // 操作に対するブローカーコメント（デフォルトは取引サーバの返したコードの記述）
      //		"rid:",res.request_id,       // ディスパッチの際に、端末によって設定されたリクエストID
      //		"rte:",res.retcode_external,"_"); // 外部取引システムのリターンコード
     }
  };

exLOG Log;

//----------------------------------------------------------------------
//↓↓↓↓↓↓↓↓↓↓↓↓経済指標関数↓↓↓↓↓↓↓↓↓↓↓
//----------------------------------------------------------------------
#ifdef __MQL4__

// イベント頻度
enum ENUM_CALENDAR_EVENT_FREQUENCY
  {
   CALENDAR_FREQUENCY_NONE = 0,	// Release frequency is not set
   CALENDAR_FREQUENCY_WEEK,    	// Released once a week
   CALENDAR_FREQUENCY_MONTH,  	// Released once a month
   CALENDAR_FREQUENCY_QUARTER, 	// Released once a quarter
   CALENDAR_FREQUENCY_YEAR,     // Released once a year
   CALENDAR_FREQUENCY_DAY       // Released once a day
  };


// 経済指標の種類（例: GDP, CPI, 雇用統計など）
enum ENUM_CALENDAR_EVENT_TYPE
  {
   CALENDAR_TYPE_EVENT = 0,				//Event (meeting, speech, etc.)
   CALENDAR_TYPE_INDICATOR,             // Indicator
   CALENDAR_TYPE_HOLIDAY             // Holiday
  };

// 経済指標のセクター（例: 政府, 労働, 消費など）
enum ENUM_CALENDAR_EVENT_SECTOR
  {
   CALENDAR_SECTOR_NONE = 0,			//Sector is not set
   CALENDAR_SECTOR_MARKET,            // 市場
   CALENDAR_SECTOR_GDP,             // 国内総生産（Gross Domestic Product、GDP）
   CALENDAR_SECTOR_JOBS,        // Labor market
   CALENDAR_SECTOR_PRICES,     // Prices
   CALENDAR_SECTOR_MONEY,      // Money
   CALENDAR_SECTOR_TRADE,          // 取引
   CALENDAR_SECTOR_GOVERNMENT,        // 政府
   CALENDAR_SECTOR_BUSINESS,   // Business
   CALENDAR_SECTOR_CONSUMER,          // 消費
   CALENDAR_SECTOR_HOUSING,       // Housing
   CALENDAR_SECTOR_TAXES, 				// Taxes
   CALENDAR_SECTOR_HOLIDAYS              // Holidays
  };

// 経済指標の重要度
enum ENUM_CALENDAR_EVENT_IMPORTANCE
  {
   CALENDAR_IMPORTANCE_NONE = 0,   // Importance is not set
   CALENDAR_IMPORTANCE_LOW,    		// Low importance
   CALENDAR_IMPORTANCE_MODERATE,    // Medium importance
   CALENDAR_IMPORTANCE_HIGH       // High importance
  };

// 経済指標データの単位（例: 百万ドル, 千人, %など）
enum ENUM_CALENDAR_EVENT_UNIT
  {
   CALENDAR_UNIT_NONE = 0,			//Measurement unit is not set
   CALENDAR_UNIT_PERCENT,         // %
   CALENDAR_UNIT_CURRENCY,         // National currency
   CALENDAR_UNIT_HOUR,       // Hours
   CALENDAR_UNIT_JOB,        // Jobs
   CALENDAR_UNIT_RIG,        // Drilling rigs
   CALENDAR_UNIT_USD,             // USD
   CALENDAR_UNIT_PEOPLE,             // People
   CALENDAR_UNIT_MORTGAGE,             // Mortgage loans
   CALENDAR_UNIT_VOTE,             // Votes
   CALENDAR_UNIT_BARREL,             // Barrels
   CALENDAR_UNIT_CUBICFEET,             // Cubic feet
   CALENDAR_UNIT_POSITION,             // Non-commercial net positions
   CALENDAR_UNIT_BUILDING            // Buildings
  };


enum ENUM_CALENDAR_EVENT_MULTIPLIER
  {
   CALENDAR_MULTIPLIER_NONE = 0,		// Multiplier is not set
   CALENDAR_MULTIPLIER_THOUSANDS,      // Thousands
   CALENDAR_MULTIPLIER_MILLIONS,      // Millions
   CALENDAR_MULTIPLIER_BILLIONS,      // Billions
   CALENDAR_MULTIPLIER_TRILLIONS         // Trillions
  };


enum ENUM_CALENDAR_EVENT_IMPACT
  {
   CALENDAR_IMPACT_NA = 0,			// Impact is not set
   CALENDAR_IMPACT_POSITIVE,      	// Positive impact
   CALENDAR_IMPACT_NEGATIVE         // Negative impact
  };

// 経済カレンダー・タイムゾーン指定
enum ENUM_CALENDAR_EVENT_TIMEMODE
  {
   CALENDAR_TIMEMODE_DATETIME = 0,	//ソースはイベントの正確な時間を公開します
   CALENDAR_TIMEMODE_DATE,			//終日イベント
   CALENDAR_TIMEMODE_NOTIME,			//ソースはイベントの時間を公開しない
   CALENDAR_TIMEMODE_TENTATIVE			//ソースはイベントの日を公開するが時間を公開しません。時間はイベントの発生時に指定されます。
  };

struct MqlCalendarCountry
  {
   ulong                               id;                   // 国ID(ISO 3166-1)
   string                             name;                 // 国名(現在のターミナルエンコーディング)
   string                             code;                 // 国コード名(ISO 3166-1 alpha-2)
   string                             currency;             // 国の通貨コード
   string                             currency_symbol;       // 国の通貨の銘柄
   string                             url_name;             // mql5.comウェブサイトURLに使用される国名
  };

struct MqlCalendarEvent
  {
   ulong                               id;                   // イベントID
   ENUM_CALENDAR_EVENT_TYPE           type;                 // ENUM_CALENDAR_EVENT_TYPE列挙対からのイベントタイプ
   ENUM_CALENDAR_EVENT_SECTOR         sector;               // イベントが関連する部門
   ENUM_CALENDAR_EVENT_FREQUENCY      frequency;             // イベントの頻度
   ENUM_CALENDAR_EVENT_TIMEMODE       time_mode;             // イベント時間モード
   ulong                               country_id;           // 国ID
   ENUM_CALENDAR_EVENT_UNIT          unit;                 // 経済指標値の単位
   ENUM_CALENDAR_EVENT_IMPORTANCE     importance;           // イベントの重要度
   ENUM_CALENDAR_EVENT_MULTIPLIER     multiplier;           // 経済指標値の乗数
   uint                               digits;               // 小数点以下の桁数
   string                             source_url;           // イベント発表源のURL
   string                             event_code;           // イベントコード
   string                             name;                 // イベント名(現在のターミナルエンコーディング)
  };

struct MqlCalendarValue
  {
   ulong                               id;                   // 値ID
   ulong                               event_id;             // イベントID
   datetime                           time;                 // イベントの日時
   datetime                           period;               // イベント報告期間
   int                                 revision;             // 報告期間に関連して発表された指標の改訂
   long                               actual_value;         // ppmでの実際の値(設定されていない場合はLONG_MIN)
   long                               prev_value;           // ppmでの前の値(設定されていない場合はLONG_MIN)
   long                               revised_prev_value;   // ppmでの改訂された前の値(設定されていない場合はLONG_MIN)
   long                               forecast_value;       // ppmでの予測値(設定されていない場合はLONG_MIN)
   ENUM_CALENDAR_EVENT_IMPACT         impact_type;           // 為替レートへの潜在的影響
   //--- 値を確認する関数
   bool                         HasActualValue(void) const;   // actual_valueが設定されている場合はtrueを返す
   bool                         HasPreviousValue(void) const; // prev_valueが設定されている場合はtrueを返す
   bool                         HasRevisedValue(void) const;  // revised_prev_valueが設定されている場合はtrueを返す
   bool                         HasForecastValue(void) const; // forecast_valueが設定されている場合はtrueを返す
   //--- 値を受け取る関数
   double                       GetActualValue(void) const;   // actual_valueを返す(値が設定されていない場合はnan)
   double                       GetPreviousValue(void) const; // prev_valueを返す(値が設定されていない場合はnan)
   double                       GetRevisedValue(void) const;  // revised_prev_valueを返す(値が設定されていない場合はnan)
   double                       GetForecastValue(void) const; // forecast_valueを返す(値が設定されていない場合はnan)
  };

// MQL4で定義する必要があるヘルパー定数を定義
#define CALENDAR_IMPORTANCE_HIGH 3

#endif

// --- ファイル名と定数 ---
#define CALENDAR_COUNTRY_FILE_NAME "country.csv"
#define CALENDAR_EVENT_FILE_NAME   "event.csv"

// --- Valueデータファイル名 ---
//#define CALENDAR_VALUE_ALL_FILE_NAME "value_all.csv"       // 長期バックテスト用
#define CALENDAR_VALUE_RECENT_FILE_NAME "value_recent.csv" // リアルタイム運用用
#define CALENDAR_VALUE_YEAR_FORMAT "value_all_%d.csv"      // 年分割ファイル名フォーマット


//----------------------------------------------------------------------
//↓↓↓↓↓↓↓↓↓↓↓↓経済指標関数↓↓↓↓↓↓↓↓↓↓↓
//----------------------------------------------------------------------

//+------------------------------------------------------------------+
//| 経済指標値のフィールドを示すENUM (抽出用)                        |
//+------------------------------------------------------------------+
enum ENUM_CALENDAR_VALUE_FIELD
{
    CALENDAR_FIELD_ACTUAL = 0,
    CALENDAR_FIELD_PREV,
    CALENDAR_FIELD_REVISED,
    CALENDAR_FIELD_FORECAST
    // CALENDAR_FIELD_IMPACT は ENUM であり数値ではないため除外
};

//+------------------------------------------------------------------+
//| MqlRatesの価格フィールドを示すENUM (抽出用)                      |
//+------------------------------------------------------------------+
enum ENUM_RATES_FIELD
{
    RATES_FIELD_OPEN = 0,
    RATES_FIELD_HIGH,
    RATES_FIELD_LOW,
    RATES_FIELD_CLOSE,
    RATES_FIELD_TICK_VOLUME,
    RATES_FIELD_REAL_VOLUME
};


//----------------------------------------------------------------------
//↑↑↑↑↑↑↑↑↑↑↑↑経済指標関数↑↑↑↑↑↑↑↑↑↑↑↑
//----------------------------------------------------------------------

class EXMQL
  {
private:

public:
                     EXMQL();
                    ~EXMQL();
   bool              OrderSend(MqlTradeRequest &request,MqlTradeResult &result);
   bool              OrderSelect(ulong ticket);
   ulong             OrderGetTicket(int index);
   long              AccountInfoInteger(ENUM_ACCOUNT_INFO_INTEGER property_id);
#ifdef __MQL4__
   long              AccountInfoInteger(ENUM_ACCOUNT_INFO_INTEGER_EXMQL  property_id);
#endif
   long              SymbolInfoInteger(string name,ENUM_SYMBOL_INFO_INTEGER prop_id);
   double            SymbolInfoDouble(string name,ENUM_SYMBOL_INFO_DOUBLE prop_id);
   string            SymbolInfoString(string name,ENUM_SYMBOL_INFO_STRING prop_id);
#ifdef __MQL4__
   long              SymbolInfoInteger(string name,ENUM_SYMBOL_INFO_INTEGER_EXMQL prop_id);
#endif
   bool              PositionSelectByTicket(ulong ticket);
   int               PositionsTotal(void);
   ulong             PositionGetTicket(int index);
   long              PositionGetInteger(ENUM_POSITION_PROPERTY_INTEGER property_id);
   double            PositionGetDouble(ENUM_POSITION_PROPERTY_DOUBLE property_id);
   string            PositionGetString(ENUM_POSITION_PROPERTY_STRING  property_id);

   int               iAC(string symbol,ENUM_TIMEFRAMES period);
   int               iADX(string symbol,ENUM_TIMEFRAMES period,int adx_period);
   int               iMA(string symbol,ENUM_TIMEFRAMES period,int ma_period,
           int ma_shift,ENUM_MA_METHOD ma_method,ENUM_APPLIED_PRICE applied_price);
   int               iStochastic(string symbol,ENUM_TIMEFRAMES period,int Kperiod,int Dperiod,
                   int slowing,ENUM_MA_METHOD ma_method,ENUM_STO_PRICE  price_field);
   int               iBands(string symbol,ENUM_TIMEFRAMES period,int bands_period,
              int bands_shift,double deviation,ENUM_APPLIED_PRICE applied_price);
   int               iRSI(string symbol,ENUM_TIMEFRAMES period,int ma_period,ENUM_APPLIED_PRICE applied_price);
   int               iCCI(string symbol,ENUM_TIMEFRAMES period,int ma_period,ENUM_APPLIED_PRICE applied_price);
   int               iSAR(string symbol,ENUM_TIMEFRAMES period,double step,double maximum);
   int               iFractals(string symbol,ENUM_TIMEFRAMES period);

   //   template<typename CusTyp1,typename CusTyp2,typename CusTyp3,typename CusTyp4,typename CusTyp5,typename CusTyp6>
   int               iCustom(string symbol,ENUM_TIMEFRAMES period,string name);
   template<typename CusTyp1>
   int               iCustom(string symbol,ENUM_TIMEFRAMES period,string name,CusTyp1 para1);
   template<typename CusTyp1,typename CusTyp2>
   int               iCustom(string symbol,ENUM_TIMEFRAMES period,string name,CusTyp1 para1,
               CusTyp2 para2);
   template<typename CusTyp1,typename CusTyp2,typename CusTyp3>
   int               iCustom(string symbol,ENUM_TIMEFRAMES period,string name,  CusTyp1 para1,
               CusTyp2 para2,
               CusTyp3 para3);
   template<typename CusTyp1,typename CusTyp2,typename CusTyp3,typename CusTyp4>
   int               iCustom(string symbol,ENUM_TIMEFRAMES period,string name,  CusTyp1 para1,
               CusTyp2 para2,
               CusTyp3 para3,
               CusTyp4 para4);
   //                                                                  CusTyp4 para4);
   //                                                                  CusTyp5 para5,
   //                                                                  CusTyp6 para6);
   //
   //   int sum(First first, Rest... rest) {
   //  return first + sum(rest...);
   //}

   //   int iCustom(string symbol,ENUM_TIMEFRAMES period,string name,Object );
   //   int iCustom(string symbol,ENUM_TIMEFRAMES period,string name,void para1);
   //   int iCustom(string symbol,ENUM_TIMEFRAMES period,string name,void para1,void para2);
   //   int iCustom(string symbol,ENUM_TIMEFRAMES period,string name,void para1,void para2,void para3);
   //   int iCustom(string symbol,ENUM_TIMEFRAMES period,string name,void para1,void para2,void para3,void para4);
   //   int iCustom(string symbol,ENUM_TIMEFRAMES period,string name,void para1,void para2,void para3,void para4,void para5);


   int               CopyBuffer(int indicator_handle,int buffer_num,
                  int start_pos,int count,double &buffer[]);
   int               CopyBuffer(int indicator_handle,int buffer_num,datetime start_time,
                  int count,double &buffer[]);
   int               CopyBuffer(int indicator_handle,int buffer_num,datetime start_time,
                  datetime  stop_time,double &buffer[]);
   bool              IndicatorRelease(int indicator_handle);
   void              OutRequest(MqlTradeRequest &req);
   void              OutResult(MqlTradeResult &res);
   long              OrderGetInteger(ENUM_ORDER_PROPERTY_INTEGER  property_id);
   double            OrderGetDouble(ENUM_ORDER_PROPERTY_DOUBLE  property_id);
   string            OrderGetString(ENUM_ORDER_PROPERTY_STRING  property_id);

#ifdef __MQL4__
   datetime          TypeTime_to_DateTime(ENUM_ORDER_TYPE_TIME type_time,datetime time);
   ENUM_ORDER_TYPE_TIME DateTime_to_TypeTime(datetime time);
   MqlTechnicalIndicatorsHandle TIHandle[];
   int               HandleVolume;
#endif

   //----------------------------------------------------------------------
   //| Aegis追加機能（Phase 1）                                           |
   //----------------------------------------------------------------------
   
   // EA停止処理
   void StopEA();
   
   // 致命的エラー判定
   bool IsFatalError(int error_code);
   
   //----------------------------------------------------------------------
   //↓↓↓↓↓↓↓↓↓↓↓↓経済指標関数↓↓↓↓↓↓↓↓↓↓↓
   //----------------------------------------------------------------------


   bool              CalendarCountryById(
      const long          country_id,    // 国ID
      MqlCalendarCountry&  country       // 国の説明を受け取るための配列
   );
   bool              CalendarEventById(
      ulong                event_id,    // イベントID
      MqlCalendarEvent&    event       // イベントの説明を受け取るための変数
   );
   bool              CalendarValueById(
      ulong                value_id,    // イベント値ID
      MqlCalendarValue&    value       // イベント値を受け取るための変数
   );
   int               CalendarCountries(
      MqlCalendarCountry& countries[]       // カレンダーの国の説明を受け取る配列
   );
   int               CalendarEventByCountry(
      string               country_code,    // 国コード名(ISO 3166-1 alpha-2)
      MqlCalendarEvent&    events[]         // 説明配列を受け取るための変数
   );
	int CalendarEventByCountrySub(string country_code, MqlCalendarEvent& events[]);
   bool              CalendarValueHistoryByEvent(
      ulong              event_id,          // イベントID
      MqlCalendarValue& values[],         // 値の説明の配列
      datetime          datetime_from,    // 期間の左の境界
      datetime          datetime_to     // 期間の右の境界
   );






   bool              CalendarValueHistory(
      MqlCalendarValue& values[],             // 値の説明の配列
      datetime          datetime_from,        // 期間の左の境界
      datetime          datetime_to,         // 期間の右の境界
      const string       country_code,    // 国コード名(ISO 3166-1 alpha-2)
      const string       currency         // 国の通貨コード名
   );
   int               CalendarValueLastByEvent(
      ulong                event_id,      // イベントID
      ulong&              change_id,    // イベント値ID
      MqlCalendarValue&    values[]     // 値の説明の配列
   );
   int               CalendarValueLast(
      ulong&              change_id,            // イベント値ID
      MqlCalendarValue&    values[],           // 値の説明の配列
      const string         country_code,    // 国コード名(ISO 3166-1 alpha-2)
      const string         currency         // 国の通貨コード名
   );


//----------------------------------------------------------------------
//経済指標関数
//----------------------------------------------------------------------
private:
// --- Calendar データキャッシュ (新実装) ---
    MqlCalendarCountry m_countries[];
    datetime           m_countries_last_modified;
    bool               m_countries_loaded;
    
    MqlCalendarEvent   m_events[];
    datetime           m_events_last_modified;
    bool               m_events_loaded;
    
    // Valueデータのキャッシュ（全年分を保持）
    MqlCalendarValue   m_values[];
    bool               m_values_year_loaded[50];  // 2000-2049年のフラグ (index: year-2000)
    datetime           m_values_last_modified;
    bool               m_values_loaded;
    
    // --- Calendar ヘルパー関数 (新実装) ---
    int  LoadCountriesFromCSV();
    int  LoadEventsFromCSV();
    int  LoadValuesFromYear(int year, MqlCalendarValue &values[]);
    bool IsFileUpdated(string filename, datetime last_time);
    
    // Value配列操作用ヘルパー
    void SortValuesByTime(MqlCalendarValue &array[]);
    int  RemoveDuplicates(MqlCalendarValue &array[]);
    void ExtractYearFromCache(int year, MqlCalendarValue &values[]);
    
    // --- その他のヘルパー関数 ---
    bool GetDoubleArray(MqlCalendarValue &source[], double &target[], ENUM_CALENDAR_VALUE_FIELD field_id);
    bool GetDoubleArray(MqlRates &source[], double &target[], ENUM_RATES_FIELD field_id);
    bool StructArrayCopy(MqlCalendarCountry &to_array[], MqlCalendarCountry &from_array[]);
    bool StructArrayCopy(MqlCalendarEvent &to_array[], MqlCalendarEvent &from_array[]);


public:

// CalendarControl クラスのパブリックセクションに追加
//---

//+------------------------------------------------------------------+
//| (汎用ロギングシステム)                   |
//+------------------------------------------------------------------+
    string m_log_file;
    LOG_LEVEL m_min_level;
    
    string GetLevelString(LOG_LEVEL level) 
    {
        switch(level) 
        {
            case LOG_DEBUG:    return "DEBUG";
            case LOG_INFO:     return "INFO ";
            case LOG_WARNING:  return "WARN ";
            case LOG_ERROR:    return "ERROR";
            case LOG_CRITICAL: return "CRIT ";
            default:           return "UNKNW";
        }
    }
    
    void WriteLog(LOG_LEVEL level, string message) 
    {
        if (level < m_min_level) return;
        
        datetime now = TimeCurrent();
        // ログファイルのフォーマット: [日時] [レベル] メッセージ
        string log_line = StringFormat("%s [%s] %s", 
                                       TimeToString(now, TIME_DATE|TIME_SECONDS),
                                       GetLevelString(level),
                                       message);
        
        // コンソール出力
        Print(log_line);
        
        // ファイル出力 (FILE_COMMON, FILE_ANSIを厳守)
        // FILE_WRITE | FILE_READ は、既存ログを保持しつつ末尾に追記するため
        int handle = FileOpen(m_log_file, FILE_WRITE | FILE_READ | FILE_TXT | FILE_ANSI | FILE_COMMON);
        if (handle != INVALID_HANDLE) 
        {
            FileSeek(handle, 0, SEEK_END); // ファイルの末尾に移動
            FileWriteString(handle, log_line + "\n");
            FileClose(handle);
        }
    }
    
public:
    void Logger (void) 
    {
        // ログファイル名を初期化
        m_log_file = EXMQL_LOG_FILE_NAME;
        m_min_level = LOG_INFO; // デフォルトではINFO以上を出力
    }
    
    void SetMinLevel(LOG_LEVEL level) { m_min_level = level; }
    
    // ログ書き込みAPI
    void Debug(string msg)    { WriteLog(LOG_DEBUG, msg); }
    void Info(string msg)     { WriteLog(LOG_INFO, msg); }
    void Warning(string msg)  { WriteLog(LOG_WARNING, msg); }
    void Error(string msg)    { WriteLog(LOG_ERROR, msg); }
    void Critical(string msg) { WriteLog(LOG_CRITICAL, msg); }
    
    // パフォーマンス統計のログ (Valueロード後の処理時間計測などに使用)
    void LogStats(string operation, int record_count, int duration_ms) 
    {
        string msg = StringFormat("%s: %d records in %d ms (%.2f rec/sec)",
                                 operation,
                                 record_count,
                                 duration_ms,
                                 (duration_ms > 0) ? (record_count * 1000.0 / duration_ms) : 0);
        Info(msg);
    }


//+------------------------------------------------------------------+
//| [Helper] GMT時刻をブローカーサーバー時刻に変換する                 |
//|          MT5/MT4のテスター環境の時差を自動計算するロジック           |
//+------------------------------------------------------------------+
datetime ConvertGMTToBrokerTime(datetime gmt_time)
{
#ifdef __MQL5__
    // MQL5: TimeCurrent()とTimeGMT()の差でオフセットを計算
    datetime server_time = TimeCurrent();
    datetime current_gmt_time = TimeGMT(); 
    long offset_sec = server_time - current_gmt_time;
    
    // 指標時刻（GMT）にオフセットを加える
    return (datetime)(gmt_time + offset_sec); 
#endif

#ifdef __MQL4__
    // MQL4: TimeCurrent()とTimeGMT()の差分を利用（MQL4でもTimeGMT()は存在しないが、
    // テスターではTimeCurrent()がブローカー時刻として動作する前提で、
    // 確実な時差計算にはTimezone APIが必要なため、MQL5側ロジックに任せる）
    
    // MQL4では、TimeCurrent()がローカルかサーバーか環境によって異なるため、
    // 確実な変換ロジックは実装が難しいため、MQL5のロジックに任せて、
    // とりあえずコンパイルを通すため、0オフセットで返すか、MQL4のOrderSendで定義されているTimeDaylightSavings()のような関数を利用します。
    
    // 今回はMQL5実行なので、MQL4は省略します。
    return gmt_time; 
#endif
}


//+------------------------------------------------------------------+
//		ライブラリ
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Helper: MqlCalendarValue 配列を Time フィールドでソートする      |
//|         (非再帰・反復クイックソート版)                           |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| 非再帰版クイックソート (MqlCalendarValue配列用)                     |
//| システムスタックを使わず、whileループと自前スタックで安全に処理を行う      |
//+------------------------------------------------------------------+
void QuickSortIterative(MqlCalendarValue &array[])
{
    int count = ArraySize(array);
    if(count <= 1) return;

    // スタック用配列（ソート範囲のインデックスを保存）
    // クイックソートの再帰深度は log2(N) なので、要素数数億でも深度は100あれば十分です
    int stack_left[100];
    int stack_right[100];
    int stack_pos = 0;

    // 最初の範囲（全体）をスタックに積む
    stack_left[0] = 0;
    stack_right[0] = count - 1;
    stack_pos++;

    // スタックが空になるまでループ
    while(stack_pos > 0)
    {
        // スタックから範囲を取り出す
        stack_pos--;
        int left = stack_left[stack_pos];
        int right = stack_right[stack_pos];

        // パーティション分割の処理
        int i = left;
        int j = right;
        // ピボット（基準値）は中央の要素の時間を使用
        datetime pivot = array[(left + right) / 2].time;
        ulong pivot_id = array[(left + right) / 2].id; // 時間が同じ場合のサブ比較用

        while(i <= j)
        {
            // 左からピボット以上の値を探す
            // (時間が同じ場合はIDで比較して安定性を高める)
            while(array[i].time < pivot || (array[i].time == pivot && array[i].id < pivot_id))
                i++;

            // 右からピボット以下の値を探す
            while(array[j].time > pivot || (array[j].time == pivot && array[j].id > pivot_id))
                j--;

            // 値を交換
            if(i <= j)
            {
                MqlCalendarValue temp = array[i];
                array[i] = array[j];
                array[j] = temp;
                i++;
                j--;
            }
        }

        // 分割された左側範囲をスタックに積む（要素が残っている場合）
        if(left < j)
        {
            if(stack_pos < 100) // 安全ガード
            {
                stack_left[stack_pos] = left;
                stack_right[stack_pos] = j;
                stack_pos++;
            }
            else
            {
                Print("EXMQL: Critical Warning - Sort Stack Overflow!");
            }
        }

        // 分割された右側範囲をスタックに積む（要素が残っている場合）
        if(i < right)
        {
            if(stack_pos < 100) // 安全ガード
            {
                stack_left[stack_pos] = i;
                stack_right[stack_pos] = right;
                stack_pos++;
            }
            else
            {
                Print("EXMQL: Critical Warning - Sort Stack Overflow!");
            }
        }
    }
}



  };


//----------------------------------------------------
//インスタンス生成
//----------------------------------------------------


EXMQL exMQL;

//----------------------------------------------------
//                    コンストラクタ
//----------------------------------------------------
EXMQL::EXMQL()
  {
	// Calendar関連の初期化
	m_countries_loaded = false;
	m_countries_last_modified = 0;
	m_events_loaded = false;
	m_events_last_modified = 0;
	
	// Valueキャッシュの初期化
	m_values_loaded = false;
	m_values_last_modified = 0;
	ArrayInitialize(m_values_year_loaded, false);
	
#ifdef __MQL5__
#endif
#ifdef __MQL4__
   HandleVolume = 0;
	Logger();
#endif
  }
//----------------------------------------------------
//                    デストラクタ
//----------------------------------------------------
EXMQL::~EXMQL()
  {
  }


//----------------------------------------------------
//+------------------------------------------------------------------+
//| クラス定義                                                       |
//+------------------------------------------------------------------+
//class CalendarControl
//  {

//+------------------------------------------------------------------+
//| 1. LoadCountriesFromCSV - 国データをロード                        |
//+------------------------------------------------------------------+
int EXMQL::LoadCountriesFromCSV()
{
    string filename = "country.csv";
    
    // ファイルを開く（FILE_TXTモードで1行ずつ読む）
    int handle = FileOpen(filename, FILE_READ|FILE_TXT|FILE_ANSI|FILE_COMMON);
    if(handle == INVALID_HANDLE)
    {
        Print("EXMQL ERROR: Cannot open ", filename, " Error: ", GetLastError());
        return 0;
    }
    
    // 配列をクリア
    ArrayResize(m_countries, 0);
    int count = 0;
    
    // ヘッダー行をスキップ
    if(!FileIsEnding(handle))
    {
        string header = FileReadString(handle);
    }
    
    // 期待されるフィールド数 (6)
    const int EXPECTED_COUNTRY_FIELDS = 6;
    
    // データ行を読み込み
    while(!FileIsEnding(handle))
    {
        string line = FileReadString(handle);
        if(StringLen(line) == 0) continue;
        
        // カンマで分割
        string fields[];
        int field_count = StringSplit(line, ',', fields);
        
        if(field_count < EXPECTED_COUNTRY_FIELDS)
        {
            Print("EXMQL: WARNING - Country CSV line skipped due to insufficient fields: ", line);
            continue;
        }
        
        // 配列リサイズ
        ArrayResize(m_countries, count + 1);
        
        // CSVフォーマット: ID,Name,Code,Currency,CurrencySymbol,URLName
        int i = 0;
        m_countries[count].id              = (ulong)StringToInteger(fields[i++]);
        m_countries[count].name            = fields[i++];
        m_countries[count].code            = fields[i++];
        m_countries[count].currency        = fields[i++];
        m_countries[count].currency_symbol = fields[i++];
        m_countries[count].url_name        = fields[i++];
        
        count++;
    }
    
    FileClose(handle);
    
    // 更新時刻を記録
    m_countries_last_modified = (datetime)FileGetInteger(filename, FILE_MODIFY_DATE, true);
    m_countries_loaded = true;
    
    Print("EXMQL: Loaded ", count, " countries from ", filename);
    return count;
}

//+------------------------------------------------------------------+
//| 2. LoadEventsFromCSV - イベントデータをロード                     |
//+------------------------------------------------------------------+
int EXMQL::LoadEventsFromCSV()
{
    string filename = "event.csv";
    
    // ファイルを開く（FILE_TXTモードで1行ずつ読む）
    int handle = FileOpen(filename, FILE_READ|FILE_TXT|FILE_ANSI|FILE_COMMON);
    if(handle == INVALID_HANDLE)
    {
        Print("EXMQL ERROR: Cannot open ", filename, " Error: ", GetLastError());
        return 0;
    }
    
    // 配列をクリア
    ArrayResize(m_events, 0);
    int count = 0;
    
    // ヘッダー行をスキップ
    if(!FileIsEnding(handle))
    {
        string header = FileReadString(handle);
    }
    
    // 期待されるフィールド数 (13)
    const int EXPECTED_EVENT_FIELDS = 13;
    
    // データ行を読み込み
    while(!FileIsEnding(handle))
    {
        string line = FileReadString(handle);
        if(StringLen(line) == 0) continue;
        
        // カンマで分割
        string fields[];
        int field_count = StringSplit(line, ',', fields);
        
        if(field_count < EXPECTED_EVENT_FIELDS)
        {
            Print("EXMQL: WARNING - Event CSV line skipped due to insufficient fields (Got ", field_count, "): ", line);
            continue;
        }
        
        // 配列リサイズ
        ArrayResize(m_events, count + 1);
        
        // CSVフォーマット: ID,Type,Sector,Frequency,TimeMode,CountryID,Unit,Importance,Multiplier,Digits,SourceURL,EventCode,Name
        int i = 0;
        m_events[count].id          = (ulong)StringToInteger(fields[i++]);
        m_events[count].type        = (ENUM_CALENDAR_EVENT_TYPE)StringToInteger(fields[i++]);
        m_events[count].sector      = (ENUM_CALENDAR_EVENT_SECTOR)StringToInteger(fields[i++]);
        m_events[count].frequency   = (ENUM_CALENDAR_EVENT_FREQUENCY)StringToInteger(fields[i++]);
        m_events[count].time_mode   = (ENUM_CALENDAR_EVENT_TIMEMODE)StringToInteger(fields[i++]);
        m_events[count].country_id  = (ulong)StringToInteger(fields[i++]);
        m_events[count].unit        = (ENUM_CALENDAR_EVENT_UNIT)StringToInteger(fields[i++]);
        m_events[count].importance  = (ENUM_CALENDAR_EVENT_IMPORTANCE)StringToInteger(fields[i++]);
        m_events[count].multiplier  = (ENUM_CALENDAR_EVENT_MULTIPLIER)StringToInteger(fields[i++]);
        m_events[count].digits      = (uint)StringToInteger(fields[i++]);
        m_events[count].source_url  = fields[i++];
        m_events[count].event_code  = fields[i++];
        m_events[count].name        = fields[i++];
        
        count++;
    }
    
    FileClose(handle);
    
    // 更新時刻を記録
    m_events_last_modified = (datetime)FileGetInteger(filename, FILE_MODIFY_DATE, true);
    m_events_loaded = true;
    
    Print("EXMQL: Loaded ", count, " events from ", filename);
    return count;
}

//+------------------------------------------------------------------+
//| 3. IsFileUpdated - ファイル更新チェック                           |
//+------------------------------------------------------------------+
bool EXMQL::IsFileUpdated(string filename, datetime last_time)
{
    // FileGetInteger でファイルの更新時刻を取得（ファイルオープン不要）
    datetime current_time = (datetime)FileGetInteger(filename, FILE_MODIFY_DATE, true);
    
    if(current_time == 0)
    {
        // ファイルが存在しない、またはエラー
        return false;
    }
    
    // 前回ロード時刻より新しければtrue
    return (current_time > last_time);
}

//+------------------------------------------------------------------+
//| 4. LoadValuesFromYear - 指定年のvalueデータをロード               |
//+------------------------------------------------------------------+
int EXMQL::LoadValuesFromYear(int year, MqlCalendarValue &values[])
{
    // 年のインデックス計算（2000年を基準）
    int year_index = year - 2000;
    
    // 範囲チェック
    if(year_index < 0 || year_index >= 50)
    {
        Print("EXMQL: ERROR - Year out of range: ", year);
        return 0;
    }
    
    // ========== キャッシュチェック ==========
    if(m_values_year_loaded[year_index])
    {
        Print("EXMQL: Using cached data for year ", year);
        ExtractYearFromCache(year, values);
        return ArraySize(values);
    }
    
    // ========== CSV読み込み ==========
    Print("EXMQL: Loading year ", year, " from CSV...");
    
    string filename = StringFormat(CALENDAR_VALUE_YEAR_FORMAT, year);
    
    // ファイルを開く（FILE_TXTモードで1行ずつ読む）
    int handle = FileOpen(filename, FILE_READ|FILE_TXT|FILE_ANSI|FILE_COMMON);
    
    if(handle == INVALID_HANDLE)
    {
        // ファイルが存在しない年もあるので、エラーは出さない
        m_values_year_loaded[year_index] = true; // 次回は読み込まない
        return 0;
    }
    
    // 一時配列に読み込み
    MqlCalendarValue temp_values[];
    int count = 0;
    
    // ヘッダー行をスキップ
    if(!FileIsEnding(handle))
    {
        string header = FileReadString(handle);
    }
    
    const int EXPECTED_VALUE_FIELDS = 10;
    
    // データ行を読み込み
    while(!FileIsEnding(handle))
    {
        string line = FileReadString(handle);
        if(StringLen(line) == 0) continue;
        
        string fields[];
        int field_count = StringSplit(line, ',', fields);
        
        if(field_count < EXPECTED_VALUE_FIELDS)
        {
            continue;
        }
        
        ArrayResize(temp_values, count + 1);
        
        int i = 0;
        temp_values[count].id                  = (ulong)StringToInteger(fields[i++]);
        temp_values[count].event_id            = (ulong)StringToInteger(fields[i++]);
        temp_values[count].time                = StringToTime(fields[i++]);
        temp_values[count].period              = StringToTime(fields[i++]);
        temp_values[count].revision            = (int)StringToInteger(fields[i++]);
        temp_values[count].actual_value        = (long)StringToInteger(fields[i++]);
        temp_values[count].prev_value          = (long)StringToInteger(fields[i++]);
        temp_values[count].revised_prev_value  = (long)StringToInteger(fields[i++]);
        temp_values[count].forecast_value      = (long)StringToInteger(fields[i++]);
        temp_values[count].impact_type         = (ENUM_CALENDAR_EVENT_IMPACT)StringToInteger(fields[i++]);
        
        count++;
        
        // 進捗表示（5000件ごと）
        if((count % 5000) == 0)
        {
            Print("[EXMQL-016-Progress] 読み込み中: ", count, "件");
        }
    }
    
    FileClose(handle);
    
    if(count > 0)
    {
        Print("EXMQL: Loaded ", count, " values from ", filename);
        
        // ========== m_values配列に追加 ==========
        int old_size = ArraySize(m_values);
        ArrayResize(m_values, old_size + count);
        
        for(int i = 0; i < count; i++)
        {
            m_values[old_size + i] = temp_values[i];
        }
        
        // ========== ソート ==========
        Print("EXMQL: Sorting all data...");
        SortValuesByTime(m_values);
        
        // ========== 重複削除 ==========
        Print("EXMQL: Removing duplicates...");
        int new_size = RemoveDuplicates(m_values);
        Print("EXMQL: Data cleaned. Final size: ", new_size);
        
        // フラグ更新
        m_values_year_loaded[year_index] = true;
        m_values_loaded = true;
        m_values_last_modified = TimeCurrent();
        
        // ========== 該当年を抽出して返す ==========
        ExtractYearFromCache(year, values);
    }
    
    return ArraySize(values);
}

//+------------------------------------------------------------------+
//| 5. CalendarCountries - 国データ取得                               |
//+------------------------------------------------------------------+
int EXMQL::CalendarCountries(MqlCalendarCountry &countries[])
{
    Print("[EXMQL-030] CalendarCountries 呼び出し");
    
#ifdef __MQL5__
    // リアル環境のみ標準APIを使用
    if(!MQLInfoInteger(MQL_TESTER) && !MQLInfoInteger(MQL_VISUAL_MODE))
    {
        Print("[EXMQL-031] 標準API使用");
        return ::CalendarCountries(countries);
    }
    Print("[EXMQL-032] CSV読み込みモード");
#endif
    // テスター環境/MQL4環境ではCSVから読み込み
    
    // 初回ロードまたはファイル更新チェック
    if(!m_countries_loaded || IsFileUpdated("country.csv", m_countries_last_modified))
    {
        Print("[EXMQL-033] CSVファイル読み込み開始");
        LoadCountriesFromCSV();
    }
    
    // キャッシュからコピー
    int size = ArraySize(m_countries);
    ArrayResize(countries, size);
    
    for(int i = 0; i < size; i++)
    {
        countries[i] = m_countries[i];
    }
    
    Print("[EXMQL-034] 国データ取得完了: ", size, "件");
    return size;
}

//+------------------------------------------------------------------+
//| 6. CalendarEventById - イベント情報取得                           |
//+------------------------------------------------------------------+
bool EXMQL::CalendarEventById(ulong event_id, MqlCalendarEvent &event)
{
    // ★このPrintは大量に呼ばれるので、デバッグ時のみ有効化
    // Print("[EXMQL-040] CalendarEventById 呼び出し: ID=", event_id);
    
#ifdef __MQL5__
    // リアル環境のみ標準APIを使用
    if(!MQLInfoInteger(MQL_TESTER) && !MQLInfoInteger(MQL_VISUAL_MODE))
    {
        return ::CalendarEventById(event_id, event);
    }
#endif
    // テスター環境/MQL4環境ではCSVから読み込み
    
    // 初回ロードまたはファイル更新チェック
    if(!m_events_loaded || IsFileUpdated("event.csv", m_events_last_modified))
    {
        Print("[EXMQL-041] CSVファイル読み込み開始");
        LoadEventsFromCSV();
    }
    
    // キャッシュから線形探索
    int size = ArraySize(m_events);
    for(int i = 0; i < size; i++)
    {
        if(m_events[i].id == event_id)
        {
            event = m_events[i];
            return true;
        }
    }
    
    // 見つからなかった
    Print("[EXMQL-042] イベントが見つかりません: ID=", event_id);
    return false;
}

//+------------------------------------------------------------------+
//| 7. CalendarValueHistory - メイン検索関数                          |
//+------------------------------------------------------------------+
bool EXMQL::CalendarValueHistory(
    MqlCalendarValue &values[],
    datetime datetime_from,
    datetime datetime_to,
    const string country_code = NULL,
    const string currency = NULL
)
{
    Print("[EXMQL-001] CalendarValueHistory 開始");
    Print("[EXMQL-002] 期間: ", TimeToString(datetime_from), " 〜 ", TimeToString(datetime_to));

#ifdef __MQL5__
    Print("[EXMQL-003] 環境: MQL5");
    Print("[EXMQL-004] テスター: ", MQLInfoInteger(MQL_TESTER));
    Print("[EXMQL-005] ビジュアル: ", MQLInfoInteger(MQL_VISUAL_MODE));
    
    // リアル環境のみ標準APIを使用
    if(!MQLInfoInteger(MQL_TESTER) && !MQLInfoInteger(MQL_VISUAL_MODE))
    {
        Print("[EXMQL-006] 標準API使用");
	    return (bool)::CalendarValueHistory(values, datetime_from, datetime_to, country_code, currency);
	}
    Print("[EXMQL-007] CSV読み込みモード");
#else
    Print("[EXMQL-008] 環境: MQL4");
#endif
    // テスター環境/MQL4環境では年分割ファイルから検索
    
    ArrayResize(values, 0);
    
    // 検索期間の年を特定
    MqlDateTime dt_from, dt_to;
    TimeToStruct(datetime_from, dt_from);
    TimeToStruct(datetime_to, dt_to);
    
    int year_from = dt_from.year;
    int year_to = dt_to.year;
    
    Print("[EXMQL-009] 検索年: ", year_from, " 〜 ", year_to);
    
    // 各年のファイルからロード
    for(int year = year_from; year <= year_to; year++)
    {
        LoadValuesFromYear(year, values);
    }
    
    // データがロードされたか確認
    int total_count = ArraySize(values);
    Print("[EXMQL-018] ロード完了: 合計 ", total_count, " 件");
    
    if(total_count == 0)
    {
        Print("[EXMQL-019] エラー: データが0件");
        Print("EXMQL: No value data loaded for period ", 
              TimeToString(datetime_from), " to ", TimeToString(datetime_to));
        return false;
    }
    
    Print("EXMQL: Total ", total_count, " values loaded before filtering");
    
    // --- フィルタリング処理 ---
    
    Print("[EXMQL-020] フィルタ前: ", ArraySize(values), "件");
    
    // 1. 時刻フィルタ
    Print("[EXMQL-050] 時刻フィルタ開始");
    Print("[EXMQL-051] datetime_from = ", datetime_from, " (", TimeToString(datetime_from), ")");
    Print("[EXMQL-052] datetime_to = ", datetime_to, " (", TimeToString(datetime_to), ")");
    
    int write_pos = 0;
    for(int i = 0; i < total_count; i++)
    {
        // 最初の3件だけ詳細表示
        if(i < 3)
        {
            Print("[EXMQL-053] values[", i, "].time = ", values[i].time, " (", TimeToString(values[i].time), ")");
        }
        
        if(values[i].time >= datetime_from && values[i].time <= datetime_to)
        {
            if(write_pos != i)
            {
                values[write_pos] = values[i];
            }
            write_pos++;
        }
    }
    ArrayResize(values, write_pos);
    Print("[EXMQL-054] 時刻フィルタ完了: ", write_pos, "件マッチ");
    
    // ★ データサンプル出力（最初3件）
    if(write_pos > 0)
    {
        Print("[EXMQL-055] === データサンプル（最初3件） ===");
        for(int i = 0; i < MathMin(3, write_pos); i++)
        {
            Print("[EXMQL-056] [", i, "] id=", values[i].id, 
                  " event_id=", values[i].event_id,
                  " time=", TimeToString(values[i].time),
                  " actual=", values[i].actual_value,
                  " prev=", values[i].prev_value);
        }
    }
    
    Print("EXMQL: After time filter: ", write_pos, " values");
    
    // 2. 国コードフィルタ
    if(country_code != NULL && country_code != "")
    {
        Print("[EXMQL-060] 国コードフィルタ開始: country_code='", country_code, "'");
        
        // イベントデータをロード（国との紐付けに必要）
        if(!m_events_loaded || IsFileUpdated("event.csv", m_events_last_modified))
        {
            LoadEventsFromCSV();
        }
        
        // 国コードから国IDを取得
        if(!m_countries_loaded || IsFileUpdated("country.csv", m_countries_last_modified))
        {
            LoadCountriesFromCSV();
        }
        
        // 複数国コード対応（カンマ区切り）
        string country_codes[];
        int code_count = StringSplit(country_code, ',', country_codes);
        Print("[EXMQL-061] 国コード分割数: ", code_count);
        
        // 各コードの前後の空白を除去
        for(int i = 0; i < code_count; i++)
        {
            StringTrimLeft(country_codes[i]);
            StringTrimRight(country_codes[i]);
            Print("[EXMQL-062] 国コード[", i, "]: '", country_codes[i], "'");
        }
        
        // 対象国IDリストを作成
        ulong target_country_ids[];
        ArrayResize(target_country_ids, 0);
        
        for(int i = 0; i < code_count; i++)
        {
            for(int j = 0; j < ArraySize(m_countries); j++)
            {
                if(m_countries[j].code == country_codes[i])
                {
                    int size = ArraySize(target_country_ids);
                    ArrayResize(target_country_ids, size + 1);
                    target_country_ids[size] = m_countries[j].id;
                    Print("[EXMQL-063] 国コード '", country_codes[i], "' → 国ID: ", m_countries[j].id);
                    break;
                }
            }
        }
        
        Print("[EXMQL-064] 対象国ID数: ", ArraySize(target_country_ids));
        
        // サンプルデータの詳細チェック（最初3件）
        Print("[EXMQL-065] === サンプルデータの国チェック ===");
        for(int i = 0; i < MathMin(3, ArraySize(values)); i++)
        {
            ulong event_id = values[i].event_id;
            ulong country_id = 0;
            string event_name = "?";
            
            for(int j = 0; j < ArraySize(m_events); j++)
            {
                if(m_events[j].id == event_id)
                {
                    country_id = m_events[j].country_id;
                    event_name = m_events[j].name;
                    break;
                }
            }
            
            // country_idから国コードを逆引き
            string found_country_code = "?";
            for(int k = 0; k < ArraySize(m_countries); k++)
            {
                if(m_countries[k].id == country_id)
                {
                    found_country_code = m_countries[k].code;
                    break;
                }
            }
            
            Print("[EXMQL-066] [", i, "] event_id=", event_id, 
                  " country_id=", country_id, 
                  " code='", found_country_code, "'",
                  " name='", event_name, "'");
        }
        
        // 国IDでフィルタリング
        write_pos = 0;
        for(int i = 0; i < ArraySize(values); i++)
        {
            // このvalueのevent_idからcountry_idを取得
            ulong event_id = values[i].event_id;
            ulong country_id = 0;
            
            for(int j = 0; j < ArraySize(m_events); j++)
            {
                if(m_events[j].id == event_id)
                {
                    country_id = m_events[j].country_id;
                    break;
                }
            }
            
            // 対象国IDリストに含まれるかチェック
            bool match = false;
            for(int k = 0; k < ArraySize(target_country_ids); k++)
            {
                if(country_id == target_country_ids[k])
                {
                    match = true;
                    break;
                }
            }
            
            if(match)
            {
                if(write_pos != i)
                {
                    values[write_pos] = values[i];
                }
                write_pos++;
            }
        }
        ArrayResize(values, write_pos);
        Print("EXMQL: After country filter: ", write_pos, " values");
    }
    
    // 3. 通貨フィルタ
    if(currency != NULL && currency != "")
    {
        // 通貨コードから国IDを取得
        if(!m_countries_loaded || IsFileUpdated("country.csv", m_countries_last_modified))
        {
            LoadCountriesFromCSV();
        }
        
        ulong target_country_ids[];
        ArrayResize(target_country_ids, 0);
        
        for(int i = 0; i < ArraySize(m_countries); i++)
        {
            if(m_countries[i].currency == currency)
            {
                int size = ArraySize(target_country_ids);
                ArrayResize(target_country_ids, size + 1);
                target_country_ids[size] = m_countries[i].id;
            }
        }
        
        // イベントデータが必要
        if(!m_events_loaded || IsFileUpdated("event.csv", m_events_last_modified))
        {
            LoadEventsFromCSV();
        }
        
        // 通貨でフィルタリング
        write_pos = 0;
        for(int i = 0; i < ArraySize(values); i++)
        {
            ulong event_id = values[i].event_id;
            ulong country_id = 0;
            
            for(int j = 0; j < ArraySize(m_events); j++)
            {
                if(m_events[j].id == event_id)
                {
                    country_id = m_events[j].country_id;
                    break;
                }
            }
            
            bool match = false;
            for(int k = 0; k < ArraySize(target_country_ids); k++)
            {
                if(country_id == target_country_ids[k])
                {
                    match = true;
                    break;
                }
            }
            
            if(match)
            {
                if(write_pos != i)
                {
                    values[write_pos] = values[i];
                }
                write_pos++;
            }
        }
        ArrayResize(values, write_pos);
        Print("EXMQL: After currency filter: ", write_pos, " values");
    }
    
    Print("[EXMQL-021] フィルタ後: ", ArraySize(values), "件");
    Print("[EXMQL-022] CalendarValueHistory 完了");
    Print("EXMQL: CalendarValueHistory completed. Final count: ", ArraySize(values));
    return (ArraySize(values) > 0);
}

//+------------------------------------------------------------------+
//| 補足: CalendarValueHistoryByEvent                                 |
//+------------------------------------------------------------------+
bool EXMQL::CalendarValueHistoryByEvent(
    ulong event_id,
    MqlCalendarValue &values[],
    datetime datetime_from,
    datetime datetime_to
)
{
#ifdef __MQL5__
    return (bool)::CalendarValueHistoryByEvent(event_id, values, datetime_from, datetime_to);
#else
    // 全データを取得してからevent_idでフィルタ
    if(!CalendarValueHistory(values, datetime_from, datetime_to))
    {
        return false;
    }
    
    int write_pos = 0;
    for(int i = 0; i < ArraySize(values); i++)
    {
        if(values[i].event_id == event_id)
        {
            if(write_pos != i)
            {
                values[write_pos] = values[i];
            }
            write_pos++;
        }
    }
    ArrayResize(values, write_pos);
    
    return (write_pos > 0);
#endif
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int  EXMQL::CalendarValueLastByEvent(
   ulong                event_id,      // イベントID
   ulong&              change_id,    // イベント値ID
   MqlCalendarValue&    values[]     // 値の説明の配列
)
  {
#ifdef __MQL5__
   if(MQLInfoInteger(MQL_TESTER) || MQLInfoInteger(MQL_VISUAL_MODE))
     {
     }
   else
     {
     }
#endif
#ifdef __MQL4__
   if(IsTesting())
     {
     }
   else
     {
     }
#endif
   return 0;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int  EXMQL::CalendarValueLast(
   ulong&              change_id,            // イベント値ID
   MqlCalendarValue&    values[],           // 値の説明の配列
   const string         country_code = NULL,  // 国コード名(ISO 3166-1 alpha-2)
   const string         currency = NULL       // 国の通貨コード名
)
  {
#ifdef __MQL5__
   if(MQLInfoInteger(MQL_TESTER) || MQLInfoInteger(MQL_VISUAL_MODE))
     {
     }
   else
     {
     }
#endif
#ifdef __MQL4__
   if(IsTesting())
     {
     }
   else
     {
     }
#endif
   return 0;
  }


//----------------------------------------------------------------------
//↑↑↑↑↑↑↑↑↑↑↑↑経済指標関数↑↑↑↑↑↑↑↑↑↑↑↑
//----------------------------------------------------------------------



//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool  EXMQL::OrderSend(MqlTradeRequest &request,MqlTradeResult &result)
  {
#ifdef __MQL5__
   return(::OrderSend(request,result));
#endif

#ifdef __MQL4__

   int cmd = 0;                     // 注文タイプ
   int ticket = -1;
   bool success = false;                // 戻り値(true/false)
   string rtn_comment = "";
   ulong ticket_to_modify = 0;

// --- 注文種別判定 (省略) ---
   switch(request.type)
     {
      case ORDER_TYPE_BUY:
         cmd = OP_BUY;
         break;
      case ORDER_TYPE_SELL:         //成行売り注文。
         cmd = OP_SELL;
         break;
      case ORDER_TYPE_BUY_LIMIT:    //買い指値注文。
         cmd = OP_BUYLIMIT;
         break;
      case ORDER_TYPE_SELL_LIMIT:   //売り指値注文。
         cmd = OP_SELLLIMIT;
         break;
      case ORDER_TYPE_BUY_STOP:     //買い逆指値注文。
         cmd = OP_BUYSTOP;
         break;
      case ORDER_TYPE_SELL_STOP:     //売り逆指値注文。
         cmd = OP_SELLSTOP;
         break;
      case(ENUM_ORDER_TYPE)ORDER_TYPE_BUY_STOP_LIMIT:
         Print("(A001)ORDER_TYPE_BUY_STOP_LIMITはサポートされていません");
         return false;
      case(ENUM_ORDER_TYPE)ORDER_TYPE_SELL_STOP_LIMIT:
         Print("(A002)ORDER_TYPE_SELL_STOP_LIMITはサポートされていません");
         return false;
      case(ENUM_ORDER_TYPE)ORDER_TYPE_CLOSE_BY:
         Print("(A003)ORDER_TYPE_CLOSE_BYはサポートされていません");
         return false;
      default:
         Print("(A004)OrderSendで未知のrequest.typeが使用されました：",EnumToString(request.type));
         Print("(A005)サポートされていないORDER_TYPEが指定されました");
         return false;
         break;
     }

   switch(request.type_time)
     {
      case ORDER_TIME_GTC:             //有効期限なし
      case ORDER_TIME_DAY:             //その日だけ有効
      case ORDER_TIME_SPECIFIED:       //datetimeで指定した日時まで
      case ORDER_TIME_SPECIFIED_DAY:   //datetimeで指定した日が終わるまで
         request.expiration = TypeTime_to_DateTime(request.type_time,request.expiration);
         break;
      default:
         Print("(A006)サポートされていないTimeInForceが使用されました:", EnumToString(request.type_time));
         return false;
     }

   switch(request.action)
     {
      case TRADE_ACTION_DEAL:       //成行注文(request.typeで判断)/約定(クローズ)
      case TRADE_ACTION_PENDING:    //指値注文(request.typeで判断)
         if(request.position == 0)  //position==0：新規注文
           {
            // 新規注文
            ticket = ::OrderSend(request.symbol,
                                 cmd,
                                 request.volume,
                                 request.price,
                                 (int)request.deviation,
                                 request.sl,
                                 request.tp,
                                 request.comment,
                                 (int)request.magic,
                                 request.expiration,
                                 clrNONE);
            // [修正2] 新規注文失敗時の判定強化
            if(ticket != -1)
              {
               success = true;
              }
            rtn_comment = OrderComment();
           }
         else   // position!=0：決済
           {
            // [修正3/4] OrderSelectの範囲拡大と決済価格の修正
            if(!::OrderSelect((int)request.position,SELECT_BY_TICKET,MODE_TRADES))
              {
               if(!::OrderSelect((int)request.position,SELECT_BY_TICKET,MODE_HISTORY))   // 履歴から探す
                 {
                  Print("(A007)OrderSelect失敗：Close対象（チケット：）",request.position,"が見つかりません");
                  return false;
                 }
              }

            // 決済価格を現在の市場価格に設定 (Bid/Ask)
            double close_price = (::OrderType() == OP_BUY) ? ::SymbolInfoDouble(::OrderSymbol(),SYMBOL_BID) : ::SymbolInfoDouble(::OrderSymbol(),SYMBOL_ASK);

            success = ::OrderClose((int)request.position,request.volume,close_price,(int)request.deviation,clrNONE);
            request.price = close_price; // result.priceに反映させるため上書き
            rtn_comment = OrderComment();
            if(success == true)
              {
               result.retcode	= TRADE_RETCODE_DONE;
               result.deal		= (ulong)request.position;
               result.order	= (ulong)request.position;
               result.volume	= request.volume;
               result.price	= request.price;
               result.comment	= rtn_comment;
               return true;
              }
           }
         break;
      case TRADE_ACTION_SLTP:       //確定したポジションの決済逆指値、決済指値の変更
      case TRADE_ACTION_MODIFY:     //未決注文のパラメータを変更j
         ticket_to_modify = 0;
         if(request.order != 0)
           {
            ticket_to_modify = request.order;
           }
         else
            if(request.position != 0)
              {
               ticket_to_modify = request.position;
              }
            else
              {
               Print("(A008)OrderModify失敗：対象となる注文またはポジションが指定されていません");
               return false;
              }


         // [修正3] OrderSelectの範囲拡大
         if(!::OrderSelect((int)ticket_to_modify,SELECT_BY_TICKET,MODE_TRADES))
           {
            if(!::OrderSelect((int)request.position,SELECT_BY_TICKET,MODE_HISTORY))
              {
               Print("(A009)OrderSelect失敗：Modify対象（チケット：）",ticket_to_modify,"が見つかりません");
               return false;
              }
           }
         success = ::OrderModify((int)ticket_to_modify,request.price,request.sl,request.tp,request.expiration,clrNONE);
         if(success == true)
           {
           }
         else
           {
           }
         rtn_comment = OrderComment();
         break;
      case TRADE_ACTION_REMOVE:     //未決注文を削除
         // MQL5仕様の request.order を使用
         // [修正3] OrderSelectの範囲拡大
         if(!::OrderSelect((int)request.order,SELECT_BY_TICKET,MODE_TRADES))
           {
            if(!::OrderSelect((int)request.order,SELECT_BY_TICKET,MODE_HISTORY))
              {
               Print("(A010)OrderSelect失敗：Delete対象（チケット：）",request.order,"が見つかりません");
               return false;
              }
           }
         success = ::OrderDelete((int)request.order,clrNONE);
         if(success == true)
           {
           }
         else
           {
           }
         rtn_comment = OrderComment();
         break;
      case TRADE_ACTION_CLOSE_BY:   //反対ポジションの決済(未サポート)
      default:
         Print("(A011)OrderSendで未知のrequest.actionが使用されました：",EnumToString(request.action));
         Print("(A012)サポートされていないactionが指定されました");
         return false;
         break;
     }

//注文結果の編集
// [修正2] 新規注文成功時の判定強化
   if(success == true)                         //注文が正常に終了した時
     {
      if(request.action == TRADE_ACTION_DEAL || request.action == TRADE_ACTION_PENDING)
        {
         result.retcode	= TRADE_RETCODE_PLACED;
        }
      else
        {
         result.retcode	= TRADE_RETCODE_DONE;
        }

      if(request.action == TRADE_ACTION_DEAL || request.action == TRADE_ACTION_PENDING)
        {
         result.deal		= (ulong)ticket;
         result.order	= (ulong)ticket;
        }
      else
        {
         result.deal		= (request.position != 0) ? request.position : request.order;
         result.order	= (request.order    != 0) ? request.order : request.position ;
        }
      if((ticket != -1) && (request.action == TRADE_ACTION_DEAL || request.action == TRADE_ACTION_PENDING))
        {
         if(::OrderSelect(ticket,SELECT_BY_TICKET))
           {

            result.volume	= ::OrderLots();
            result.price	= ::OrderOpenPrice();
           }
        }
      else
        {
         result.volume	= request.volume;
         result.price	= request.price;
        }
     }
   else                                                  //注文がエラーで終了した時
     {
      //      result.retcode = ::GetLastError();                   // 操作のリターンコード
      result.retcode = _LastError;
      switch(result.retcode)
        {
         case ERR_REQUOTE: // リクオート (138)
            result.retcode = TRADE_RETCODE_REQUOTE; // リクオート
            break;
         //	    case :
         //	        result.retcode = TRADE_RETCODE_REJECT; // リクエスト却下
         //	        break;
         //	    case :
         //	        result.retcode = TRADE_RETCODE_CANCEL; // リクエストキャンセル
         //	        break;
         //	    case :
         //	        result.retcode = TRADE_RETCODE_PLACED; // 注文が出されました
         //	        break;
         case ERR_NO_ERROR:
            result.retcode = TRADE_RETCODE_DONE;	// リクエストが完了しました
            break;
         //	    case :
         //	        result.retcode = TRADE_RETCODE_DONE_PARTIAL; // リクエストが一部のみ完了しました
         //	        break;
         //	    case :
         //	        result.retcode = TRADE_RETCODE_ERROR; // リクエスト処理エラーが発生
         //	        break;
         case ERR_TRADE_TIMEOUT: // タイムアウト (128 または 146, 8)
         case ERR_WEBREQUEST_TIMEOUT:
            result.retcode = TRADE_RETCODE_TIMEOUT; // リクエスト処理のタイムアウト
            break;
         case ERR_UNKNOWN_SYMBOL:
         case ERR_INVALID_FUNCTION_PARAMVALUE:
            result.retcode = TRADE_RETCODE_INVALID; // リクエストが無効です
            break;
         case ERR_INVALID_TRADE_VOLUME: // 無効なボリューム (131)
            result.retcode = TRADE_RETCODE_INVALID_VOLUME; // 無効なボリューム
            break;
         case ERR_INVALID_PRICE: // 無効な価格 (129)
         case ERR_INVALID_PRICE_PARAM:
            result.retcode = TRADE_RETCODE_INVALID_PRICE; // 無効な価格
            break;
         case ERR_INVALID_STOPS: // 無効なストップレベル (130)
            result.retcode = TRADE_RETCODE_INVALID_STOPS; // 無効なストップレベル（SL/TPが近すぎる）
            break;
         case ERR_TRADE_DISABLED: // 取引が無効化 (133)
         case ERR_TRADE_NOT_ALLOWED: // 取引が許可されていない (4109)
            result.retcode = TRADE_RETCODE_TRADE_DISABLED; // 取引が無効化
            break;
         case ERR_MARKET_CLOSED: // 市場休場 (132)
            result.retcode = TRADE_RETCODE_MARKET_CLOSED; // 市場休場
            break;
         //		case ERR_NOT_ENOUGH_MEMORY:
         case ERR_NOT_ENOUGH_MONEY: // 資金不足 (134)
            result.retcode = TRADE_RETCODE_NO_MONEY;	//十分な資金がありません
            break;
         case ERR_PRICE_CHANGED: // 価格変更 (135)
            result.retcode = TRADE_RETCODE_PRICE_CHANGED; // 価格変更
            break;
         //	    case :
         //	        result.retcode = TRADE_RETCODE_PRICE_OFF; // リクエストのためのクォートがありません
         //	        break;
         case ERR_TRADE_EXPIRATION_DENIED:
            result.retcode = TRADE_RETCODE_INVALID_EXPIRATION; //リクエストの注文期限が無効
            break;
         //	    case :
         //	        result.retcode = TRADE_RETCODE_ORDER_CHANGED; //注文状態が変更されました
         //	        break;
         case ERR_TOO_MANY_REQUESTS: // リクエストが多すぎる (141)
            result.retcode = TRADE_RETCODE_TOO_MANY_REQUESTS; // リクエストが多すぎる
            break;
         //	    case ERR_NO_RESULT: // 処理結果なし (1)
         //	        result.retcode = TRADE_RETCODE_NO_CHANGES; // 修正が必要ない
         //	        break;
         //	    case : // 自動売買無効 (4108)
         //	        result.retcode = TRADE_RETCODE_SERVER_DISABLES_AT; //サーバによる自動売買無効
         //	        break;
         //	    case : // 自動売買無効 (4108)
         //	        result.retcode = TRADE_RETCODE_CLIANT_DISABLES_AT; //クライアントによる自動売買無効
         //	        break;
         //	    case :
         //	        result.retcode = TRADE_RETCODE_LOCKED; //処理のためリクエストロック
         //	        break;
         //	    case ERR_TRADE_MODIFY_DENIED: // 変更禁止 (145)
         //	    case ERR_TRADE_FROZEN: // 凍結ポジション (147)
         //	        result.retcode = TRADE_RETCODE_FROZEN; // 注文・ポジションが凍結
         //	        break;
         //	    case :
         //	        result.retcode = TRADE_RETCODE_INVALID_FILL; //無効な注文タイプ
         //	        break;
         case ERR_NO_CONNECTION: // サーバー未接続 (6)
            result.retcode = TRADE_RETCODE_CONNECTION; //取引サーバに接続されていません
            break;
         //	    case :
         //	        result.retcode = TRADE_RETCODE_ONRY_REAL; //ライブ口座でのみ許可
         //	        break;
         //	    case :
         //	        result.retcode = TRADE_RETCODE_LIMIT_ORDERS; //未決注文数上限
         //	        break;
         //	    case :
         //	        break;
         case ERR_TRADE_TOO_MANY_ORDERS: // 注文数上限 (148)
            result.retcode = TRADE_RETCODE_LIMIT_VOLUME; //注文、ポジションの上限
            break;
         //	    case ERR_INVALID_TICKET: // 不正なチケット (4107)
         //	        result.retcode = TRADE_RETCODE_INVALID_ORDER; // 誤っている／禁止さてれいる注文タイプ
         //	        break;
         //	    case :
         //	        result.retcode = TRADE_RETCODE_POSITION_CLOSED; //すでに決済されている
         //	        break;
         //	    case :
         //	        result.retcode = TRADE_RETCODE_INVALID_CLOSED_VOLUME; //数量がポジション数量を超えている
         //	        break;
         //	    case :
         //	        result.retcode = TRADE_RETCODE_CLOSE_ORDER_EXIST; //ポジションには決済注文あり
         //	        break;
         //	    case :
         //	        result.retcode = TRADE_RETCODE_LIMIT_POSITIONS; //ポジション上限に達した
         //	        break;
         //	    case :
         //	        result.retcode = TRADE_RETCODE_REJECT_CANCEL; //未決注文の執行リスエストキャンセル
         //	        break;
         case ERR_LONG_POSITIONS_ONLY_ALLOWED:
            result.retcode = TRADE_RETCODE_LONG_ONLY; //ロングポジションのみ許可
            break;
         //	    case :
         //	        result.retcode = TRADE_RETCODE_SHORT_ONLY; //ショートポジションのみ許可
         //	        break;
         //	    case :
         //	        result.retcode = TRADE_RETCODE_CLOSE_ONLY; //ポジション決済のみ許可
         //	        break;
         //	    case :
         //	        break;
         case ERR_TRADE_PROHIBITED_BY_FIFO: // FIFO制限 (150)
            result.retcode = TRADE_RETCODE_FIFO_CLOSE; //FIFOルールのみ許可
            break;
         case ERR_TRADE_HEDGE_PROHIBITED: // ヘッジ禁止 (149)
            result.retcode = TRADE_RETCODE_HEDGE_PROHIBITED; // 両建て禁止
            break;
         default:	//判別できない場合は、MAL4のリターンコードをそのまま返す
            Print("(A013)OrderSend失敗：判別できないエラーコード：",result.retcode);
            //			result.retcode = TRADE_RETCODE_ERROR;
            break;
        }
      result.deal = 0;                                   // 実行された場合の 約定チケット
      result.order = 0;                                  // 注文された場合のチケット
      result.volume = 0;                                 // ブローカーによって確認された約定ボリューム
      result.price = 0;                                  // ブローカーによって確認された約定価格
      return false;
     }

//   result.bid = Bid;                                     // 現在の売値
//   result.ask = Ask;                                     // 現在の買値
// [修正6] コメントの反映
//   result.comment = rtn_comment;                                  // 操作に対するブローカーコメント
//   result.request_id = 0;                                // ディスパッチの際に、端末によって設定されたリクエストID
//   result.retcode_external = 0;                          // 外部取引システムのリターンコード

   return true;
#endif
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool EXMQL::OrderSelect(ulong ticket)
  {
#ifdef __MQL5__
   return(::OrderSelect(ticket));
#endif
#ifdef __MQL4__
   return(::OrderSelect((int)ticket,SELECT_BY_TICKET,MODE_TRADES));
#endif
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ulong  EXMQL::OrderGetTicket(int index)
  {
#ifdef __MQL5__
   return(::OrderGetTicket(index));
#endif
#ifdef __MQL4__
   bool bRtn = ::OrderSelect(index,SELECT_BY_POS,MODE_TRADES);
   if(bRtn == false)
      return 0;
   return(::OrderTicket());
#endif
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
long  EXMQL::OrderGetInteger(ENUM_ORDER_PROPERTY_INTEGER  property_id)
  {
#ifdef __MQL5__
   return(::OrderGetInteger(property_id));
#endif
#ifdef __MQL4__
   switch(property_id)
     {
      case ORDER_MAGIC:  //注文を出したエキスパートアドバイザーのID（各エキスパートアドバイザーは、独自のユニークな番号を作成するように設計されています）。
         return(::OrderMagicNumber());
         break;
      case ORDER_TYPE:  //注文の種類。
         switch(OrderType())
           {
            case OP_BUY:      // 買いの成行注文
               return(ORDER_TYPE_BUY);
               break;
            case OP_SELL:     // 売りの成行注文
               return(ORDER_TYPE_SELL);
               break;
            case OP_BUYLIMIT:	// 買いの指値注文
               return(ORDER_TYPE_BUY_LIMIT);
               break;
            case OP_SELLLIMIT:// 売りの指値注文
               return(ORDER_TYPE_SELL_LIMIT);
               break;
            case OP_BUYSTOP:	// 買いの逆指値注文
               return(ORDER_TYPE_BUY_STOP);
               break;
            case OP_SELLSTOP: //
               return(ORDER_TYPE_SELL_STOP);
               break;
            default:
               Print("OrderGetInteger中、OrderTypeから未知の識別子が返されました");
               break;
           }
         return 0;
         break;
      case ORDER_TYPE_TIME:  //注文ライフタイム。
         return(DateTime_to_TypeTime(OrderExpiration()));
         break;
      //   case ORDER_TICKET:  //注文チケット。各注文に割り当てられる固有番号。
      case ORDER_TIME_SETUP:  //注文設定時刻。
      case ORDER_STATE:  //注文状態。
      case ORDER_TIME_EXPIRATION:  //注文の期限。
         return(OrderExpiration());
         break;
      case ORDER_TIME_DONE:  //注文の実行及びキャンセル時刻。
      case ORDER_TIME_SETUP_MSC:  //01.01.1970 から経過したミリ秒数で表された注文の実行が出された時刻。
      case ORDER_TIME_DONE_MSC:  //01.01.1970 から経ったミリ秒で表された注文の実行/キャンセル時刻。
      case ORDER_TYPE_FILLING:  //注文充填タイプ。
      //   case ORDER_REASON:  //注文の理由またはソース。
      //   case ORDER_POSITION_ID:  //実行後すぐに注文に設定されるポジション識別。注文の実行は注文を出すか、既存のポジション変更する約定となります。このポジションの識別子がこの時点で実行される注文のために設定されています。
      //   case ORDER_POSITION_BY_ID:  //ORDER_TYPE_CLOSE_BY型の注文の為の反対ポジションの識別子。
      default:
         Print("OrderGetIntegerで未知の識別子が使用されました：",EnumToString(property_id));
         break;
     }
   return 0;
#endif
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double  EXMQL::OrderGetDouble(ENUM_ORDER_PROPERTY_DOUBLE  property_id)
  {
#ifdef __MQL5__
   return(::OrderGetDouble(property_id));
#endif
#ifdef __MQL4__

   switch(property_id)
     {
      case ORDER_SL:  //決済逆指値。
         return(::OrderStopLoss());
         break;
      case ORDER_TP:  //決済指値。
         return(::OrderTakeProfit());
         break;
      case ORDER_VOLUME_CURRENT:  //注文の現在ボリューム。
         return(::OrderLots());
         break;
      case ORDER_PRICE_OPEN:        //注文で指定された価格。
         return(::OrderOpenPrice());
         break;
      case ORDER_VOLUME_INITIAL:    //注文の初期ボリューム。
      case ORDER_PRICE_CURRENT:     //注文シンボルの現在の価格。
      case ORDER_PRICE_STOPLIMIT:   //ストップリミット注文の指値注文価格。
      default:
         Print("OrderGetDoubleで未知の識別子が使用されました：",EnumToString(property_id));
         break;
     }
   return 0;
#endif
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string  EXMQL::OrderGetString(ENUM_ORDER_PROPERTY_STRING  property_id)
  {
#ifdef __MQL5__
   return(::OrderGetString(property_id));
#endif
#ifdef __MQL4__
   return "";
#endif
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
long  EXMQL::PositionGetInteger(ENUM_POSITION_PROPERTY_INTEGER  property_id)
  {
#ifdef __MQL5__
   return(::PositionGetInteger(property_id));
#endif
#ifdef __MQL4__
   switch(property_id)
     {
      case POSITION_TICKET:
         return(::OrderTicket());
         break;
      case POSITION_TIME:
         return((int)::OrderOpenTime());
         break;
      case POSITION_TYPE:
         switch(::OrderType())
           {
            case OP_BUY:
               return(POSITION_TYPE_BUY);
               break;
            case OP_SELL:
               return(POSITION_TYPE_SELL);
               break;
            case OP_BUYLIMIT:
               return(POSITION_TYPE_BUY);
               break;
            case OP_SELLLIMIT:
               return(POSITION_TYPE_SELL);
               break;
            case OP_BUYSTOP:
               return(POSITION_TYPE_BUY);
               break;
            case OP_SELLSTOP:
               return(POSITION_TYPE_SELL);
               break;
            default:
               break;
           }
         break;
      case POSITION_MAGIC:
         return(::OrderMagicNumber());
         break;
      case POSITION_IDENTIFIER:
      case POSITION_REASON:
      case POSITION_TIME_MSC:
      case POSITION_TIME_UPDATE:
      case POSITION_TIME_UPDATE_MSC:
      default:
         Print("PositionGetIntegerで未知の識別子が使用されました：",EnumToString(property_id));
         break;
     }
   return 0;
#endif
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double  EXMQL::PositionGetDouble(ENUM_POSITION_PROPERTY_DOUBLE  property_id)
  {
#ifdef __MQL5__
   return(::PositionGetDouble(property_id));
#endif
#ifdef __MQL4__
   switch(property_id)
     {
      case POSITION_VOLUME:
         return(::OrderLots());
         break;
      case POSITION_PRICE_OPEN:
         return(::OrderOpenPrice());
         break;
      case POSITION_SL:
         return(::OrderStopLoss());
         break;
      case POSITION_TP:
         return(::OrderTakeProfit());
         break;
      case POSITION_PRICE_CURRENT:
         if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
           {
            ::RefreshRates();
            return(Bid);
           }
         else
           {
            ::RefreshRates();
            return(Ask);
           }
         break;
      case POSITION_SWAP:
         return(::OrderSwap());
         break;
      case POSITION_PROFIT:
         return(::OrderProfit());
         break;
      default:
         Print("PositionGetDoubleで未知の識別子が使用されました：",EnumToString(property_id));
         break;
     }
   return 0;
#endif
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string EXMQL::PositionGetString(ENUM_POSITION_PROPERTY_STRING  property_id)
  {
#ifdef __MQL5__
   return(::PositionGetString(property_id));
#endif
#ifdef __MQL4__
   switch(property_id)
     {
      case POSITION_SYMBOL:
         return(::OrderSymbol());
         break;
      case POSITION_COMMENT:
         return(::OrderComment());
         break;
      case POSITION_EXTERNAL_ID:
      default:
         Print("PositionGetStringで未知の識別子が使用されました：",EnumToString(property_id));
         break;
     }
   return "";
#endif
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool  EXMQL::PositionSelectByTicket(ulong  ticket)
  {
#ifdef __MQL5__
   return(::PositionSelectByTicket(ticket));
#endif
#ifdef __MQL4__
   return(::OrderSelect((int)ticket,SELECT_BY_TICKET));
#endif
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ulong  EXMQL::PositionGetTicket(int index)
  {
#ifdef __MQL5__
   return(::PositionGetTicket(index));
#endif
#ifdef __MQL4__
   if(::OrderSelect(index,SELECT_BY_POS,MODE_TRADES) == true)
     {
      return(::OrderTicket());
     }
   return 0;
#endif
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int  EXMQL::PositionsTotal(void)
  {
#ifdef __MQL5__
   return(::PositionsTotal());
#endif
#ifdef __MQL4__
   return (::OrdersTotal());
#endif
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
long  EXMQL::AccountInfoInteger(ENUM_ACCOUNT_INFO_INTEGER property_id)
  {
#ifdef __MQL5__
   return(::AccountInfoInteger(property_id));
#endif
#ifdef __MQL4__
   switch(property_id)
     {
      case ACCOUNT_LOGIN:           //口座番号。
         return(::AccountNumber());
         break;
      case ACCOUNT_LEVERAGE:        //口座レバレッジ。
         return(::AccountLeverage());
         break;
      case ACCOUNT_TRADE_MODE:      //口座取引モード。
         return(::AccountInfoInteger(ACCOUNT_TRADE_MODE));
         break;
      case ACCOUNT_LIMIT_ORDERS:    //アクティブな未決注文の最大許容数。
         return(::AccountInfoInteger(ACCOUNT_LIMIT_ORDERS));
         break;
      case ACCOUNT_TRADE_EXPERT:    //エキスパートアドバイザーで許可された取引。
         return(::AccountInfoInteger(ACCOUNT_TRADE_EXPERT));
         break;
      case ACCOUNT_TRADE_ALLOWED:   //現在の口座で許可された取引。
         return(::AccountInfoInteger(ACCOUNT_TRADE_ALLOWED));
         break;
      case ACCOUNT_MARGIN_SO_MODE:  //許容された最小証拠金を設定するモード。
         Print("AccountInfoInteger(ACCOUNT_MARGIN_SO_MODE)はサポートされていません");
         break;
      default:
         Print("AccountInfoIntegerで未知の識別子が使用されました：",EnumToString(property_id));
         break;
     }
   return -1;
#endif
  }

#ifdef __MQL4__
long  EXMQL::AccountInfoInteger(ENUM_ACCOUNT_INFO_INTEGER_EXMQL property_id)
  {
   switch(property_id)
     {
      case ACCOUNT_MARGIN_MODE:     //証拠金計算モード
         Print("AccountInfoInteger(ACCOUNT_MARGIN_MODE)はサポートされていません");
         break;
      case ACCOUNT_CURRENCY_DIGITS: //取引結果を正確に表示するために必要な口座通貨の小数点以下の桁数
         Print("AccountInfoInteger(ACCOUNT_CURRENCY_DIGITS)はサポートされていません");
         break;
      case ACCOUNT_FIFO_CLOSE:      //FIFOルールによってのみポジションを決済できることを示します。
         //プロパティ値がtrueに設定されている場合、各シンボルのポジションは、
         //最も古いものから順に同じ順序で決済されます。
         //別の注文でポジションを決済しようとした場合、適切なエラーが発生します。
         Print("AccountInfoInteger(ACCOUNT_FIFO_CLOSE)はサポートされていません");
         break;
      default:
         Print("AccountInfoIntegerで未知の識別子が使用されました：",EnumToString(property_id));
         break;
         break;
     }

   return -1;
  }
#endif

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
long  EXMQL::SymbolInfoInteger(string name,ENUM_SYMBOL_INFO_INTEGER prop_id)
  {
#ifdef __MQL5__
   return(::SymbolInfoInteger(name,prop_id));
#endif
#ifdef __MQL4__
   string symbol_name;
   if(name == NULL)
     {
      symbol_name = Symbol();
     }
   switch(prop_id)
     {
      case  SYMBOL_TRADE_EXEMODE:      //約定実行モード。
         return(::SymbolInfoInteger(symbol_name,prop_id));
         break;
      case  SYMBOL_DIGITS:             //小数点以下の桁数。
         return((long)::MarketInfo(symbol_name,MODE_DIGITS));
         break;
      case  SYMBOL_START_TIME:         //シンボル取引開始の日（通常は先物取引に使用）
         return(::SymbolInfoInteger(symbol_name,prop_id));
         break;
      case  SYMBOL_EXPIRATION_TIME:    //シンボル取引終了の日（通常は先物取引に使用）。
         return(::SymbolInfoInteger(symbol_name,prop_id));
         break;
      case  SYMBOL_SELECT:             //「気配値表示」でシンボルが選択されています。
         return(::SymbolInfoInteger(symbol_name,prop_id));
         break;
      case  SYMBOL_VISIBLE:            //シンボルは気配値表示で表示されます。
         //一部のシンボル（主に、証拠金の計算や預金通貨の利益の計算に必要なクロスレート）は
         //自動的に選択されますが、一般的に気配値表示には表示されません。
         //そのようなシンボルを表示するには、それらを明示的に選択する必要があります。
         return(::SymbolInfoInteger(symbol_name,prop_id));
         break;
      case  SYMBOL_FILLING_MODE:       //注文充填モードの可能なフラグ。
         return(::SymbolInfoInteger(symbol_name,prop_id));
         break;
      case  SYMBOL_TRADE_STOPS_LEVEL:  //現在の終値から逆指値注文を配置する場合の最少のインデント（ポイント単位）。
         return(::SymbolInfoInteger(symbol_name,prop_id));
         break;
      case  SYMBOL_SESSION_DEALS:      //現在のセッションの約定数。
         return(::SymbolInfoInteger(symbol_name,prop_id));
         break;
      case  SYMBOL_SESSION_BUY_ORDERS: //現時点での買い注文の数。
         return(::SymbolInfoInteger(symbol_name,prop_id));
         break;
      case  SYMBOL_SESSION_SELL_ORDERS://現時点での売り注文の数。
         return(::SymbolInfoInteger(symbol_name,prop_id));
         break;
      case  SYMBOL_VOLUME:             //最終約定ボリューム。
         return(::SymbolInfoInteger(symbol_name,prop_id));
         break;
      case  SYMBOL_VOLUMEHIGH:         //一日の最大ボリューム。
         return(::SymbolInfoInteger(symbol_name,prop_id));
         break;
      case  SYMBOL_VOLUMELOW:          //一日の最小ボリューム。
         return(::SymbolInfoInteger(symbol_name,prop_id));
         break;
      case  SYMBOL_TIME:               //最終の相場の時刻。
         return(::SymbolInfoInteger(symbol_name,prop_id));
         break;
      case  SYMBOL_SPREAD_FLOAT:       //変動スプレッドの表示。
         return(::SymbolInfoInteger(symbol_name,prop_id));
         break;
      case  SYMBOL_SPREAD:             //ポイント単位でのスプレッド値。
         return(::SymbolInfoInteger(symbol_name,prop_id));
         break;
      case  SYMBOL_TICKS_BOOKDEPTH:    //板情報で表示されるリクエストの最高数。要求のないキューを持っていないシンボルの場合、値はゼロに等しいです。
         return(::SymbolInfoInteger(symbol_name,prop_id));
         break;
      case  SYMBOL_TRADE_MODE:         //注文実行の種類。
         return(::SymbolInfoInteger(symbol_name,prop_id));
         break;
      case  SYMBOL_TRADE_FREEZE_LEVEL: //取引業務を凍結までの距離（ポイント単位）。
         return(::SymbolInfoInteger(symbol_name,prop_id));
         break;
      case  SYMBOL_SWAP_MODE:          //スワップ計算モデル。
         return(::SymbolInfoInteger(symbol_name,prop_id));
         break;
      case  SYMBOL_SWAP_ROLLOVER3DAYS: //トリプルスワップが加算される曜日。
         return(::SymbolInfoInteger(symbol_name,prop_id));
         break;
      case  SYMBOL_EXPIRATION_MODE:    //注文期限切れモードの可能なフラグ。
         return(::SymbolInfoInteger(symbol_name,prop_id));
         break;
      case  SYMBOL_ORDER_MODE:         //注文の種類に使用可能なフラグ。
         return(::SymbolInfoInteger(symbol_name,prop_id));
         break;
      case  SYMBOL_TRADE_CALC_MODE:    //契約価格計算モード。
         return(::SymbolInfoInteger(symbol_name,prop_id));
         break;
      default:
         Print("SymbolInfoIntegerでサポートされていない識別子が使用されました：",EnumToString(prop_id));
         break;
     }
   return 0;
#endif
  }

#ifdef __MQL4__
long  EXMQL::SymbolInfoInteger(string name,ENUM_SYMBOL_INFO_INTEGER_EXMQL prop_id)
  {
   switch(prop_id)
     {
      case  SYMBOL_SECTOR:                //資産が属する経済部門
      case  SYMBOL_INDUSTRY:              //銘柄が属する業界または経済部門
      case  SYMBOL_CUSTOM:                //カスタムシンボルです。シンボルは板情報および/または外部データソースからの他のシンボルに基づいて総合的に作成されています。
      case  SYMBOL_BACKGROUND_COLOR:      //「気配値表示」のシンボルに使用されている背景色。
      case  SYMBOL_CHART_MODE:            //シンボルバーを生成するために使用される価格の種類（BidまたはLast）。
      case  SYMBOL_EXIST:                 //Symbol with this name exists
      case  SYMBOL_TIME_MSC:              //最後の相場の1970.01.01から経過した時間(ミリ秒)
      case  SYMBOL_MARGIN_HEDGED_USE_LEG: //より大きな脚を使用したヘッジ証拠金の計算（売りまたは買い）。
      case  SYMBOL_ORDER_GTC_MODE:        //SYMBOL_EXPIRATION_MODE=SYMBOL_EXPIRATION_GTC（キャンセルされるまで有効）の場合の、決済逆指値及び決済指値の期限</ t2>。
      case  SYMBOL_OPTION_MODE:           //オプションの種類。
      case  SYMBOL_OPTION_RIGHT:          //オプション特権 (買い/売り)。
      default:
         Print("SymbolInfoIntegerで未知の識別子が使用されました：",EnumToString(prop_id));
         break;
     }
   return 0;
  }
#endif




//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double EXMQL::SymbolInfoDouble(string name,ENUM_SYMBOL_INFO_DOUBLE prop_id)
  {
#ifdef __MQL5__
   return(::SymbolInfoDouble(name,prop_id));
#endif
#ifdef __MQL4__
   string symbol_name;
   if(name == NULL)
     {
      symbol_name = Symbol();
     }
   switch(prop_id)
     {
      case  SYMBOL_BID:      //売値
         return(::SymbolInfoDouble(symbol_name,prop_id));
         break;
      case  SYMBOL_ASK:      //買値
         return(::SymbolInfoDouble(symbol_name,prop_id));
         break;
      case  SYMBOL_POINT:    //通貨ペアのポイント
         return(::SymbolInfoDouble(symbol_name,prop_id));
         break;
      case  SYMBOL_TRADE_TICK_VALUE:    //SYMBOL_TRADE_TICK_VALUE_PROFITの値
         return(::SymbolInfoDouble(symbol_name,prop_id));
         break;
      case  SYMBOL_TRADE_TICK_SIZE:
         return(::SymbolInfoDouble(symbol_name,prop_id));
         break;
      case  SYMBOL_TRADE_CONTRACT_SIZE:
         return(::SymbolInfoDouble(symbol_name,prop_id));
         break;
      case  SYMBOL_VOLUME_MIN:
         return(::SymbolInfoDouble(symbol_name,prop_id));
         break;
      case  SYMBOL_VOLUME_MAX:
         return(::SymbolInfoDouble(symbol_name,prop_id));
         break;
      case  SYMBOL_VOLUME_STEP:
         return(::SymbolInfoDouble(symbol_name,prop_id));
         break;
      case  SYMBOL_SWAP_LONG:
         return(::SymbolInfoDouble(symbol_name,prop_id));
         break;
      case  SYMBOL_SWAP_SHORT:
         return(::SymbolInfoDouble(symbol_name,prop_id));
         break;
      case  SYMBOL_MARGIN_INITIAL:
         return(::SymbolInfoDouble(symbol_name,prop_id));
         break;
      case  SYMBOL_MARGIN_MAINTENANCE:
         return(::SymbolInfoDouble(symbol_name,prop_id));
         break;
      default:
         Print("SymbolInfoDoubleでサポートされていない識別子が使用されました：",EnumToString(prop_id));
         break;
     }
   return 0;
#endif
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string EXMQL::SymbolInfoString(string name,ENUM_SYMBOL_INFO_STRING prop_id)
  {
#ifdef __MQL5__
   return(::SymbolInfoString(name,prop_id));
#endif
#ifdef __MQL4__
   string symbol_name;
   if(name == NULL)
     {
      symbol_name = Symbol();
     }
   switch(prop_id)
     {
      case  SYMBOL_CURRENCY_BASE:
         return(::SymbolInfoString(symbol_name,prop_id));
         break;
      case  SYMBOL_CURRENCY_PROFIT:
         return(::SymbolInfoString(symbol_name,prop_id));
         break;
      case  SYMBOL_CURRENCY_MARGIN:
         return(::SymbolInfoString(symbol_name,prop_id));
         break;
      case  SYMBOL_DESCRIPTION:
         return(::SymbolInfoString(symbol_name,prop_id));
         break;
      case  SYMBOL_PATH:
         return(::SymbolInfoString(symbol_name,prop_id));
         break;
      default:
         Print("SymbolInfoStringでサポートされていない識別子が使用されました：",EnumToString(prop_id));
         break;
     }
   return "";
#endif
  }


// EXMQL::iAC
int EXMQL::iAC(string symbol,ENUM_TIMEFRAMES period)
{
#ifdef __MQL5__
	return(::iAC(symbol,period));
#endif
#ifdef __MQL4__
    int rtnHandle = INVALID_HANDLE;

    if(::ArrayResize(TIHandle,HandleVolume + 1) == (HandleVolume + 1))
    {
        ::ZeroMemory(TIHandle[HandleVolume]);
        TIHandle[HandleVolume].bValid = true;
        TIHandle[HandleVolume].type = T_iAC;
        TIHandle[HandleVolume].symbol = symbol;
        TIHandle[HandleVolume].period = period;
        // iACに特化したパラメータは一旦空
        rtnHandle = HandleVolume;
        HandleVolume++;
    }
    return rtnHandle;
#endif
}
// EXMQL::iADX
int EXMQL::iADX(string symbol,ENUM_TIMEFRAMES period,int adx_period)
{
#ifdef __MQL5__
	return(::iADX(symbol,period,adx_period));
#endif
#ifdef __MQL4__
    int rtnHandle = INVALID_HANDLE;

    if(::ArrayResize(TIHandle,HandleVolume + 1) == (HandleVolume + 1))
    {
        ::ZeroMemory(TIHandle[HandleVolume]);
        TIHandle[HandleVolume].bValid = true;
        TIHandle[HandleVolume].type = T_iADX;
        TIHandle[HandleVolume].symbol = symbol;
        TIHandle[HandleVolume].period = period;
        TIHandle[HandleVolume].adx_period = adx_period; // ADX期間を格納
        rtnHandle = HandleVolume;
        HandleVolume++;
    }
    return rtnHandle;
#endif
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int  EXMQL::iMA(string symbol,                    //通貨ペア
                ENUM_TIMEFRAMES period,          //時間軸
                int ma_period,                   //平均期間
                int ma_shift,                    //シフト量
                ENUM_MA_METHOD ma_method,        //移動平均線の種類
                ENUM_APPLIED_PRICE applied_price)//始/終/高/低値の種類
  {
#ifdef __MQL5__
   return(::iMA(symbol,period,ma_period,ma_shift,ma_method,applied_price));
#endif
#ifdef __MQL4__
   int rtnHandle = INVALID_HANDLE;

   if(::ArrayResize(TIHandle,HandleVolume + 1) == (HandleVolume + 1))
     {
      ::ZeroMemory(TIHandle[HandleVolume]);
      TIHandle[HandleVolume].bValid = true;
      TIHandle[HandleVolume].type = T_iMA;
      TIHandle[HandleVolume].symbol = symbol;
      TIHandle[HandleVolume].period = period;
      TIHandle[HandleVolume].ma_period = ma_period;
      TIHandle[HandleVolume].ma_shift = ma_shift;
      TIHandle[HandleVolume].ma_method = ma_method;
      TIHandle[HandleVolume].applied_price = applied_price;
      rtnHandle = HandleVolume;
      HandleVolume++;
     }

   return rtnHandle;
#endif
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int EXMQL::iRSI(string symbol,ENUM_TIMEFRAMES period,int ma_period,ENUM_APPLIED_PRICE applied_price)
  {
#ifdef __MQL5__
   return(::iRSI(symbol,period,ma_period,applied_price));
#endif
#ifdef __MQL4__
   int rtnHandle = INVALID_HANDLE;

   if(::ArrayResize(TIHandle,HandleVolume + 1) == (HandleVolume + 1))
     {
      ::ZeroMemory(TIHandle[HandleVolume]);
      TIHandle[HandleVolume].bValid = true;
      TIHandle[HandleVolume].type = T_iRSI;
      TIHandle[HandleVolume].symbol = symbol;
      TIHandle[HandleVolume].period = period;
      TIHandle[HandleVolume].ma_period = ma_period;
      TIHandle[HandleVolume].applied_price = applied_price;
      rtnHandle = HandleVolume;
      HandleVolume++;
     }

   return rtnHandle;
#endif
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int EXMQL::iCCI(string symbol,ENUM_TIMEFRAMES period,int ma_period,ENUM_APPLIED_PRICE applied_price)
  {
#ifdef __MQL5__
   return(::iCCI(symbol,period,ma_period,applied_price));
#endif
#ifdef __MQL4__
   int rtnHandle = INVALID_HANDLE;

   if(::ArrayResize(TIHandle,HandleVolume + 1) == (HandleVolume + 1))
     {
      ::ZeroMemory(TIHandle[HandleVolume]);
      TIHandle[HandleVolume].bValid = true;
      TIHandle[HandleVolume].type = T_iRSI;
      TIHandle[HandleVolume].symbol = symbol;
      TIHandle[HandleVolume].period = period;
      TIHandle[HandleVolume].ma_period = ma_period;
      TIHandle[HandleVolume].applied_price = applied_price;
      rtnHandle = HandleVolume;
      HandleVolume++;
     }

   return rtnHandle;
#endif
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int EXMQL::iBands(string symbol,ENUM_TIMEFRAMES period,int bands_period,
                  int bands_shift,double deviation,ENUM_APPLIED_PRICE applied_price)
  {
#ifdef __MQL5__
   return(::iBands(symbol,period,bands_period,bands_shift,deviation,applied_price));
#endif
#ifdef __MQL4__
   int rtnHandle = INVALID_HANDLE;

   if(::ArrayResize(TIHandle,HandleVolume + 1) == (HandleVolume + 1))
     {
      ::ZeroMemory(TIHandle[HandleVolume]);
      TIHandle[HandleVolume].bValid = true;
      TIHandle[HandleVolume].type = T_iBands;
      TIHandle[HandleVolume].symbol = symbol;
      TIHandle[HandleVolume].period = period;
      TIHandle[HandleVolume].bands_period = bands_period;
      TIHandle[HandleVolume].bands_shift = bands_shift;
      TIHandle[HandleVolume].deviation = deviation;
      TIHandle[HandleVolume].applied_price = applied_price;
      rtnHandle = HandleVolume;
      HandleVolume++;
     }

   return rtnHandle;
#endif
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int EXMQL::iStochastic(string symbol,ENUM_TIMEFRAMES period,int Kperiod,int Dperiod,
                       int slowing,ENUM_MA_METHOD ma_method,ENUM_STO_PRICE  price_field)
  {
#ifdef __MQL5__
   return(::iStochastic(symbol,period,Kperiod,Dperiod,slowing,ma_method,price_field));
#endif
#ifdef __MQL4__
   int rtnHandle = INVALID_HANDLE;

   if(::ArrayResize(TIHandle,HandleVolume + 1) == (HandleVolume + 1))
     {
      ::ZeroMemory(TIHandle[HandleVolume]);
      TIHandle[HandleVolume].bValid = true;
      TIHandle[HandleVolume].type = T_iStochastic;
      TIHandle[HandleVolume].symbol = symbol;
      TIHandle[HandleVolume].period = period;
      TIHandle[HandleVolume].Kperiod = Kperiod;
      TIHandle[HandleVolume].Dperiod = Dperiod;
      TIHandle[HandleVolume].slowing = slowing;
      TIHandle[HandleVolume].ma_method = ma_method;
      TIHandle[HandleVolume].price_field = price_field;
      rtnHandle = HandleVolume;
      HandleVolume++;
     }

   return rtnHandle;
#endif
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int EXMQL::iSAR(string symbol,ENUM_TIMEFRAMES period,double step,double maximum)
  {
#ifdef __MQL5__
   return(::iSAR(symbol,period,step,maximum));
#endif
#ifdef __MQL4__
   return 0;
#endif
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int EXMQL::iFractals(string symbol,ENUM_TIMEFRAMES period)
  {
#ifdef __MQL5__
   return(::iFractals(symbol,period));
#endif
#ifdef __MQL4__
   return 0;
#endif

  }
///////////////////////////////////////////////////////////////////////////////
//                    iCustom
///////////////////////////////////////////////////////////////////////////////
int EXMQL::iCustom(string symbol,ENUM_TIMEFRAMES period,string name)
  {
#ifdef __MQL5__
   return(::iCustom(symbol,period,name));
#endif
#ifdef __MQL4__
   int rtnHandle = INVALID_HANDLE;

   if(::ArrayResize(TIHandle,HandleVolume + 1) == (HandleVolume + 1))
     {
      ::ZeroMemory(TIHandle[HandleVolume]);
      TIHandle[HandleVolume].bValid = true;
      TIHandle[HandleVolume].type = T_iCustom;
      TIHandle[HandleVolume].symbol = symbol;
      TIHandle[HandleVolume].period = period;
      TIHandle[HandleVolume].name   = name;
      rtnHandle = HandleVolume;
      HandleVolume++;
     }

   return rtnHandle;
#endif
  }

template<typename CusTyp1>
int EXMQL::iCustom(string symbol,ENUM_TIMEFRAMES period,string name, CusTyp1 para1)
  {
#ifdef __MQL5__
   return(::iCustom(symbol,period,name,para1));
#endif
#ifdef __MQL4__
   int rtnHandle = INVALID_HANDLE;

   if(::ArrayResize(TIHandle,HandleVolume + 1) == (HandleVolume + 1))
     {
      ::ZeroMemory(TIHandle[HandleVolume]);
      TIHandle[HandleVolume].bValid = true;
      TIHandle[HandleVolume].type = T_iCustom;
      TIHandle[HandleVolume].symbol = symbol;
      TIHandle[HandleVolume].period = period;
      TIHandle[HandleVolume].name   = name;
      TIHandle[HandleVolume].para1  = para1;
      rtnHandle = HandleVolume;
      HandleVolume++;
     }

   return rtnHandle;
#endif

  }

template<typename CusTyp1,typename CusTyp2>
int EXMQL::iCustom(string symbol,ENUM_TIMEFRAMES period,string name, CusTyp1 para1,
                   CusTyp1 para2)
  {
#ifdef __MQL5__
   return(::iCustom(symbol,period,name,para1,para2));
#endif
#ifdef __MQL4__
   int rtnHandle = INVALID_HANDLE;

   if(::ArrayResize(TIHandle,HandleVolume + 1) == (HandleVolume + 1))
     {
      ::ZeroMemory(TIHandle[HandleVolume]);
      TIHandle[HandleVolume].bValid = true;
      TIHandle[HandleVolume].type = T_iCustom;
      TIHandle[HandleVolume].symbol = symbol;
      TIHandle[HandleVolume].period = period;
      TIHandle[HandleVolume].name   = name;
      TIHandle[HandleVolume].para1  = para1;
      TIHandle[HandleVolume].para2  = para2;
      rtnHandle = HandleVolume;
      HandleVolume++;
     }

   return rtnHandle;
#endif
  }

template<typename CusTyp1,typename CusTyp2,typename CusTyp3>
int EXMQL::iCustom(string symbol,ENUM_TIMEFRAMES period,string name, CusTyp1 para1,
                   CusTyp2 para2,
                   CusTyp3 para3)
  {
#ifdef __MQL5__
   return(::iCustom(symbol,period,name,para1,para2,para3));
#endif
#ifdef __MQL4__
   int rtnHandle = INVALID_HANDLE;

   if(::ArrayResize(TIHandle,HandleVolume + 1) == (HandleVolume + 1))
     {
      ::ZeroMemory(TIHandle[HandleVolume]);
      TIHandle[HandleVolume].bValid = true;
      TIHandle[HandleVolume].type = T_iCustom;
      TIHandle[HandleVolume].symbol = symbol;
      TIHandle[HandleVolume].period = period;
      TIHandle[HandleVolume].name   = name;
      if(StringFind(name,"Guppy MMA",0) != -1)
        {
         TIHandle[HandleVolume].tf_para1  = para1;
         TIHandle[HandleVolume].tf_para2  = para2;
         TIHandle[HandleVolume].ap_para3  = para3;
        }
      rtnHandle = HandleVolume;
      HandleVolume++;
     }

   return rtnHandle;
#endif
  }


//+------------------------------------------------------------------+
//| 関数名: CopyBuffer                                               |
//| 機能: インジケータバッファからデータを配列にコピー               |
//| 引数: indicator_handle (int) - インジケータハンドル             |
//|       buffer_num (int) - バッファ番号                           |
//|       start_pos (int) - 開始位置                                |
//|       count (int) - コピー数                                    |
//|       buffer[] (double&) - データ格納用配列                     |
//| 戻値: (int) コピーされたデータ数。エラー時は -1                 |
//+------------------------------------------------------------------+
int  EXMQL::CopyBuffer(int indicator_handle,int buffer_num,int start_pos,int parCount,double &buffer[])
  {
#ifdef __MQL5__
   int rtn = ::CopyBuffer(indicator_handle,buffer_num,start_pos,parCount, buffer);
   if(rtn < 0)
      return -1;
   return (rtn);
#endif
#ifdef __MQL4__
   int i;
   switch(TIHandle[indicator_handle].type)
     {
      case T_iMA:          //移動平均（Moving Average）。
         switch(TIHandle[indicator_handle].period)
           {
            case PERIOD_CURRENT: //現在の時間軸
            case PERIOD_M1: //1分
            case PERIOD_M5: //5分
            case PERIOD_M15: //15分
            case PERIOD_M30: //30分
            case PERIOD_H1: //1時間
            case PERIOD_H4: //4時間
            case PERIOD_D1: //1日
            case PERIOD_W1: //1週間
            case PERIOD_MN1: //1ヶ月
               break;
            case PERIOD_M2: //2分
            case PERIOD_M3: //3分
            case PERIOD_M4: //4分
            case PERIOD_M6: //6分
            case PERIOD_M10: //10分
            case PERIOD_M12: //12分
            case PERIOD_M20: //20分
            case PERIOD_H2: //2時間
            case PERIOD_H3: //3時間
            case PERIOD_H6: //6時間
            case PERIOD_H8: //8時間
            case PERIOD_H12: //12時間
            default:
               Print("サポートされていない時間軸が指定されました:",EnumToString(TIHandle[indicator_handle].period));
               return 0;
               break;
           }
         ::ArrayResize(buffer,parCount);
         for(i = 0; i < parCount ; i++)
           {
            buffer[parCount - i - 1] = ::iMA(TIHandle[indicator_handle].symbol,
                                             TIHandle[indicator_handle].period,
                                             TIHandle[indicator_handle].ma_period,
                                             TIHandle[indicator_handle].ma_shift,
                                             TIHandle[indicator_handle].ma_method,
                                             TIHandle[indicator_handle].applied_price,
                                             start_pos + i);
           }
         return i;
         break;
        case T_iRSI: // ★★★ RSI対応を追加 ★★★
            switch(TIHandle[indicator_handle].period)
            {
                case PERIOD_CURRENT:
                case PERIOD_M1:
                case PERIOD_M5:
                case PERIOD_M15:
                case PERIOD_M30:
                case PERIOD_H1:
                case PERIOD_H4:
                case PERIOD_D1:
                case PERIOD_W1:
                case PERIOD_MN1:
                    break;
                default:
                    Print("サポートされていない時間軸が指定されました:",EnumToString(TIHandle[indicator_handle].period));
                    return 0;
                    break;
            }
            
            ::ArrayResize(buffer,parCount);
            for(i = 0; i < parCount ; i++)
            {
                buffer[parCount - i - 1] = ::iRSI(
                    TIHandle[indicator_handle].symbol,
                    TIHandle[indicator_handle].period,
                    TIHandle[indicator_handle].ma_period,
                    TIHandle[indicator_handle].applied_price,
                    start_pos + i
                );
            }
            return i;
            break;
      case T_iAC:          //ACオシレーター。
      case T_iAD:          //蓄積/配信（Accumulation/Distribution）。
      case T_iADX:         //平均方向性指数（Average Directional Index）。
      case T_iADXWilder:   //ウェルズワイルダーの平均方向性指数（Average Directional Index by Welles Wilder）
      case T_iAlligator:   //アリゲーター。
      case T_iAMA:         //適応型移動平均（Adaptive Moving Average）。
      case T_iAO:          //オーサムオシレーター。
      case T_iATR:         //ATR（Average True Range）。
      case T_iBearsPower:  //ベアパワー（Bears Power）。
      case T_iBands:       //ボリンジャーバンドR（Bollinger BandsR）。
      case T_iBullsPower:  //ブルパワー（Bulls Power）。
      case T_iCCI:         //コモディティチャンネルインデックス（Commodity Channel Index）。
      case T_iChaikin:     //チャイキンオシレーター（Chaikin Oscillator）。
      case T_iCustom:      //カスタム指標。
      case T_iDEMA:        //2 重指数移動平均（Double Exponential Moving Average）。
      case T_iDeMarker:    //デマーカー（DeMarker）。
      case T_iEnvelopes:   //エンベローブ（Envelopes）。
      case T_iForce:       //勢力指数（Force Index）。
      case T_iFractals:    //フラクタル。
      case T_iFrAMA:       //フラクタル適応型移動平均（Fractal Adaptive Moving Average）。
      case T_iGator:       //ゲーターオシレーター。
      case T_iIchimoku:    //一目均衡表（Ichimoku Kinko Hyo）。
      case T_iBWMFI:       //ビル・ウィリアムズのマーケットファシリテーションインデックス
      case T_iMomentum:    //モメンタム（Momentum）。
      case T_iMFI:         //マネーフローインデックス（Money Flow Index）。
      case T_iOsMA:        //移動平均オシレーター（Moving Average of Oscillator）（MACD ヒストグラム）。
      case T_iMACD:        //移動平均収束拡散法（Moving Averages Convergence-Divergence）
      case T_iOBV:         //オンバランスボリューム（On Balance Volume）。
      case T_iSAR:         //パラボリック停止・リバースシステム（Parabolic Stop And Reverse System）
      case T_iRVI:         //相対活力指数（Relative Vigor Index）。
      case T_iStdDev:      //標準偏差（Standard Deviation）。
      case T_iStochastic:  //ストキャスティックス（Stochastic Oscillator）。
      case T_iTEMA:        //3 重指数移動平均（Triple Exponential Moving Average）。
      case T_iTriX:        //3 重指数移動平均オシレーター（Triple Exponential Moving Averages Oscillator）。
      case T_iWPR:         //ウィリアムパーセントレンジ（Williams' Percent Range）。
      case T_iVIDyA:       //可変インデックス動的平均（Variable Index Dynamic Average）。
      case T_iVolumes:     //ボリューム。
      default:
         break;
     }
   return 0;
#endif
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int  EXMQL::CopyBuffer(int indicator_handle,int buffer_num,datetime start_time,int parCount,double &buffer[])
  {
#ifdef __MQL5__
   int rtn = ::CopyBuffer(indicator_handle,buffer_num,start_time,parCount, buffer);
   if(rtn < 0)
      return -1;
   return (rtn);
#endif
#ifdef __MQL4__
   int i;
   switch(TIHandle[indicator_handle].type)
     {
      case T_iMA:          //移動平均（Moving Average）。
         switch(TIHandle[indicator_handle].period)
           {
            case PERIOD_CURRENT: //現在の時間軸
            case PERIOD_M1: //1分
            case PERIOD_M5: //5分
            case PERIOD_M15: //15分
            case PERIOD_M30: //30分
            case PERIOD_H1: //1時間
            case PERIOD_H4: //4時間
            case PERIOD_D1: //1日
            case PERIOD_W1: //1週間
            case PERIOD_MN1: //1ヶ月
               break;
            case PERIOD_M2: //2分
            case PERIOD_M3: //3分
            case PERIOD_M4: //4分
            case PERIOD_M6: //6分
            case PERIOD_M10: //10分
            case PERIOD_M12: //12分
            case PERIOD_M20: //20分
            case PERIOD_H2: //2時間
            case PERIOD_H3: //3時間
            case PERIOD_H6: //6時間
            case PERIOD_H8: //8時間
            case PERIOD_H12: //12時間
            default:
               Print("サポートされていない時間軸が指定されました:",EnumToString(TIHandle[indicator_handle].period));
               return 0;
               break;
           }
         ::ArrayResize(buffer,parCount);
         for(i = 0; i < parCount ; i++)
           {
            buffer[i] = ::iMA(TIHandle[indicator_handle].symbol,
                              TIHandle[indicator_handle].period,
                              (int)start_time,
                              TIHandle[indicator_handle].ma_shift,
                              TIHandle[indicator_handle].ma_method,
                              TIHandle[indicator_handle].applied_price,
                              0);
           }
         return i;
         break;
      case T_iAC:          //ACオシレーター。
      case T_iAD:          //蓄積/配信（Accumulation/Distribution）。
      case T_iADX:         //平均方向性指数（Average Directional Index）。
      case T_iADXWilder:   //ウェルズワイルダーの平均方向性指数（Average Directional Index by Welles Wilder）
      case T_iAlligator:   //アリゲーター。
      case T_iAMA:         //適応型移動平均（Adaptive Moving Average）。
      case T_iAO:          //オーサムオシレーター。
      case T_iATR:         //ATR（Average True Range）。
      case T_iBearsPower:  //ベアパワー（Bears Power）。
      case T_iBands:       //ボリンジャーバンドR（Bollinger BandsR）。
      case T_iBullsPower:  //ブルパワー（Bulls Power）。
      case T_iCCI:         //コモディティチャンネルインデックス（Commodity Channel Index）。
      case T_iChaikin:     //チャイキンオシレーター（Chaikin Oscillator）。
      case T_iCustom:      //カスタム指標。
      case T_iDEMA:        //2 重指数移動平均（Double Exponential Moving Average）。
      case T_iDeMarker:    //デマーカー（DeMarker）。
      case T_iEnvelopes:   //エンベローブ（Envelopes）。
      case T_iForce:       //勢力指数（Force Index）。
      case T_iFractals:    //フラクタル。
      case T_iFrAMA:       //フラクタル適応型移動平均（Fractal Adaptive Moving Average）。
      case T_iGator:       //ゲーターオシレーター。
      case T_iIchimoku:    //一目均衡表（Ichimoku Kinko Hyo）。
      case T_iBWMFI:       //ビル・ウィリアムズのマーケットファシリテーションインデックス
      case T_iMomentum:    //モメンタム（Momentum）。
      case T_iMFI:         //マネーフローインデックス（Money Flow Index）。
      case T_iOsMA:        //移動平均オシレーター（Moving Average of Oscillator）（MACD ヒストグラム）。
      case T_iMACD:        //移動平均収束拡散法（Moving Averages Convergence-Divergence）
      case T_iOBV:         //オンバランスボリューム（On Balance Volume）。
      case T_iSAR:         //パラボリック停止・リバースシステム（Parabolic Stop And Reverse System）
      case T_iRSI:         //相対力指数（Relative Strength Index）。
      case T_iRVI:         //相対活力指数（Relative Vigor Index）。
      case T_iStdDev:      //標準偏差（Standard Deviation）。
      case T_iStochastic:  //ストキャスティックス（Stochastic Oscillator）。
      case T_iTEMA:        //3 重指数移動平均（Triple Exponential Moving Average）。
      case T_iTriX:        //3 重指数移動平均オシレーター（Triple Exponential Moving Averages Oscillator）。
      case T_iWPR:         //ウィリアムパーセントレンジ（Williams' Percent Range）。
      case T_iVIDyA:       //可変インデックス動的平均（Variable Index Dynamic Average）。
      case T_iVolumes:     //ボリューム。
      default:
         break;
     }
   return 0;
#endif
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int  EXMQL::CopyBuffer(int indicator_handle,int buffer_num,datetime start_time,datetime stop_time,double &buffer[])
  {
#ifdef __MQL5__
   return(::CopyBuffer(indicator_handle,buffer_num,start_time,stop_time, buffer));
#endif
#ifdef __MQL4__
   switch(TIHandle[indicator_handle].type)
     {
      case T_iMA:          //移動平均（Moving Average）。
      case T_iAC:          //ACオシレーター。
      case T_iAD:          //蓄積/配信（Accumulation/Distribution）。
      case T_iADX:         //平均方向性指数（Average Directional Index）。
      case T_iADXWilder:   //ウェルズワイルダーの平均方向性指数（Average Directional Index by Welles Wilder）
      case T_iAlligator:   //アリゲーター。
      case T_iAMA:         //適応型移動平均（Adaptive Moving Average）。
      case T_iAO:          //オーサムオシレーター。
      case T_iATR:         //ATR（Average True Range）。
      case T_iBearsPower:  //ベアパワー（Bears Power）。
      case T_iBands:       //ボリンジャーバンドR（Bollinger BandsR）。
      case T_iBullsPower:  //ブルパワー（Bulls Power）。
      case T_iCCI:         //コモディティチャンネルインデックス（Commodity Channel Index）。
      case T_iChaikin:     //チャイキンオシレーター（Chaikin Oscillator）。
      case T_iCustom:      //カスタム指標。
      case T_iDEMA:        //2 重指数移動平均（Double Exponential Moving Average）。
      case T_iDeMarker:    //デマーカー（DeMarker）。
      case T_iEnvelopes:   //エンベローブ（Envelopes）。
      case T_iForce:       //勢力指数（Force Index）。
      case T_iFractals:    //フラクタル。
      case T_iFrAMA:       //フラクタル適応型移動平均（Fractal Adaptive Moving Average）。
      case T_iGator:       //ゲーターオシレーター。
      case T_iIchimoku:    //一目均衡表（Ichimoku Kinko Hyo）。
      case T_iBWMFI:       //ビル・ウィリアムズのマーケットファシリテーションインデックス
      case T_iMomentum:    //モメンタム（Momentum）。
      case T_iMFI:         //マネーフローインデックス（Money Flow Index）。
      case T_iOsMA:        //移動平均オシレーター（Moving Average of Oscillator）（MACD ヒストグラム）。
      case T_iMACD:        //移動平均収束拡散法（Moving Averages Convergence-Divergence）
      case T_iOBV:         //オンバランスボリューム（On Balance Volume）。
      case T_iSAR:         //パラボリック停止・リバースシステム（Parabolic Stop And Reverse System）
      case T_iRSI:         //相対力指数（Relative Strength Index）。
      case T_iRVI:         //相対活力指数（Relative Vigor Index）。
      case T_iStdDev:      //標準偏差（Standard Deviation）。
      case T_iStochastic:  //ストキャスティックス（Stochastic Oscillator）。
      case T_iTEMA:        //3 重指数移動平均（Triple Exponential Moving Average）。
      case T_iTriX:        //3 重指数移動平均オシレーター（Triple Exponential Moving Averages Oscillator）。
      case T_iWPR:         //ウィリアムパーセントレンジ（Williams' Percent Range）。
      case T_iVIDyA:       //可変インデックス動的平均（Variable Index Dynamic Average）。
      case T_iVolumes:     //ボリューム。
      default:
         break;
     }
   return 0;
#endif
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool EXMQL::IndicatorRelease(int indicator_handle)
{
#ifdef __MQL5__
	return(::IndicatorRelease(indicator_handle));
#endif
#ifdef __MQL4__
    // MQL4ではハンドル解放の組み込み関数がないため、
    // 独自のハンドル管理配列(TIHandle)を無効化する
    if (indicator_handle >= 0 && indicator_handle < ArraySize(TIHandle))
    {
        TIHandle[indicator_handle].bValid = false;
        return true;
    }
    return false;
#endif
}
#ifdef __MQL4__
datetime EXMQL::TypeTime_to_DateTime(ENUM_ORDER_TYPE_TIME type_time,datetime time)
  {
   datetime rtn_time = (datetime)0;

   switch(type_time)
     {
      case ORDER_TIME_GTC:             //(0) Good till canceled. 待機注文の有効期限を設定しません（明示的にキャンセルされるまで有効です）
         rtn_time = (datetime)0;
         break;
      case ORDER_TIME_DAY:             //(1) 待機注文はその日の間だけ有効です。
         rtn_time = StringToTime(IntegerToString(Year(),4,0) + "." + IntegerToString(Month(),2,0) + "." + IntegerToString(Day(),2,0) + " " + "23:59");
         break;
      case ORDER_TIME_SPECIFIED:       //(2) 待機注文は datetime 引数で指定した日時まで有効です。
         rtn_time = time;
         break;
      case ORDER_TIME_SPECIFIED_DAY:   //(3) 待機注文は datetime 引数で指定した日が終わるまで有効です
         rtn_time = StringToTime(IntegerToString(TimeYear(time),4,0) + "." + IntegerToString(TimeMonth(time),2,0) + "." + IntegerToString(TimeDay(time),2,0) + " " + "23:59");
         break;
      default:
         Print("EXMQL::TypeTime_to_DateTimeで未知のtype_timeが指定されました");
         break;
     }
   return rtn_time;
  }
#endif

#ifdef __MQL4__
ENUM_ORDER_TYPE_TIME EXMQL::DateTime_to_TypeTime(datetime time)
  {
   ENUM_ORDER_TYPE_TIME rtn_type = 0;

   if(time == 0)
     {
      rtn_type = ORDER_TIME_GTC;
     }
   else
     {
      rtn_type = ORDER_TIME_SPECIFIED;
     }

   return rtn_type;
  }
#endif


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void EXMQL::OutRequest(MqlTradeRequest &req)
  {
   Print("action:",EnumToString(req.action));
   Print("magic:",req.magic); // エキスパートアドバイザー ID（マジックナンバー）
   Print("order:",req.order); // 注文チケット
   Print("symbol:",req.symbol); // 取引シンボル
   Print("volume",req.volume); // 約定のための要求されたボリューム（ロット単位）
   Print("price",req.price); // 価格
   Print("stoplimit:",req.stoplimit); // 注文のストップリミットレベル
   Print("sl:",req.sl); // 注文の決済逆指値レベル
   Print("tp:",req.tp);  // 注文の決済指値レベル
   Print("deviation:",req.deviation); // リクエストされた価格からの可能な最大偏差
   Print("type:",EnumToString(req.type)); // 注文の種類
   Print("type_filling:",req.type_filling); // 注文実行の種類
   Print("type_time:",req.type_time); // 注文期限切れの種類
   Print("expiration:",req.expiration); // 注文期限切れの時刻 （ORDER_TIME_SPECIFIED 型の注文）
   Print("comment:",req.comment);  // 注文コメント
   Print("position:",req.position); // Position ticket
   Print("position_by:",req.position_by); // The ticket of an opposite position
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void EXMQL::OutResult(MqlTradeResult &res)
  {
   Print("retcode:",res.retcode);
   Print("deal:",res.deal);
   Print("order:",res.order);
   Print("volume:",res.volume);
   Print("price:",res.price);
   Print("bid:",res.bid);
   Print("ask:",res.ask);
   Print("comment:",res.comment);
   Print("request_id:",res.request_id);
   Print("retcode_external:",res.retcode_external);
  }


//+------------------------------------------------------------------+
//| Helper: MqlCalendarValue 配列を Time フィールドでソートする      |
//|         (非再帰・反復クイックソート版)                           |
//+------------------------------------------------------------------+
void EXMQL::SortValuesByTime(MqlCalendarValue &array[])
{
    int size = ArraySize(array);
    if (size <= 1) return;

    // --- 自前スタックの準備 ---
    int stack_size = (int)(MathLog(size) / MathLog(2.0)) * 2 + 50;
    int stack_l[];
    int stack_r[];
    
    if(ArrayResize(stack_l, stack_size) == -1 || ArrayResize(stack_r, stack_size) == -1)
    {
        Print("EXMQL: Critical Error - Memory allocation failed for QuickSort stack.");
        return; 
    }

    int sp = 0;
    stack_l[sp] = 0;
    stack_r[sp] = size - 1;
    sp++;

    MqlCalendarValue temp;
    MqlCalendarValue pivot_val;

    while(sp > 0)
    {
        sp--;
        int left = stack_l[sp];
        int right = stack_r[sp];

        if(left >= right) continue;

        int i = left;
        int j = right;
        int pivot_idx = left + (right - left) / 2;
        pivot_val = array[pivot_idx];

        while(i <= j)
        {
            while(i < right && (array[i].time < pivot_val.time || (array[i].time == pivot_val.time && array[i].id < pivot_val.id)))
            {
                i++;
            }

            while(j > left && (array[j].time > pivot_val.time || (array[j].time == pivot_val.time && array[j].id > pivot_val.id)))
            {
                j--;
            }

            if(i <= j)
            {
                temp = array[i];
                array[i] = array[j];
                array[j] = temp;
                i++;
                j--;
            }
        }

        if(sp + 2 >= stack_size)
        {
            int new_size = stack_size * 2;
            ArrayResize(stack_l, new_size);
            ArrayResize(stack_r, new_size);
            stack_size = new_size;
        }

        if(left < j)
        {
            stack_l[sp] = left;
            stack_r[sp] = j;
            sp++;
        }
        if(i < right)
        {
            stack_l[sp] = i;
            stack_r[sp] = right;
            sp++;
        }
    }
}

//+------------------------------------------------------------------+
//| Helper: ソート済み配列から重複レコードを削除する                 |
//+------------------------------------------------------------------+
int EXMQL::RemoveDuplicates(MqlCalendarValue &array[])
{
    int total = ArraySize(array);
    if (total <= 1) return total;

    int new_size = 0;
    array[new_size] = array[0];
    new_size++;

    for (int i = 1; i < total; i++)
    {
        if (array[i].time != array[new_size - 1].time || array[i].id != array[new_size - 1].id)
        {
            array[new_size] = array[i];
            new_size++;
        }
    }

    ArrayResize(array, new_size);
    return new_size;
}

//+------------------------------------------------------------------+
//| Helper: キャッシュから該当年のデータを抽出                       |
//+------------------------------------------------------------------+
void EXMQL::ExtractYearFromCache(int year, MqlCalendarValue &values[])
{
    ArrayResize(values, 0);
    
    int total = ArraySize(m_values);
    if(total == 0) return;
    
    datetime year_start = StringToTime(StringFormat("%d.01.01 00:00:00", year));
    datetime year_end = StringToTime(StringFormat("%d.12.31 23:59:59", year));
    
    // ========== バイナリサーチで開始位置を検索 ==========
    int left = 0;
    int right = total - 1;
    int start_pos = -1;
    
    // 開始位置（year_start以上の最初の位置）を探す
    while(left <= right)
    {
        int mid = (left + right) / 2;
        if(m_values[mid].time >= year_start)
        {
            start_pos = mid;
            right = mid - 1;  // より前方を探す
        }
        else
        {
            left = mid + 1;
        }
    }
    
    // 該当データが見つからない
    if(start_pos == -1) return;
    
    // ========== バイナリサーチで終了位置を検索 ==========
    left = start_pos;
    right = total - 1;
    int end_pos = start_pos;
    
    // 終了位置（year_end以下の最後の位置）を探す
    while(left <= right)
    {
        int mid = (left + right) / 2;
        if(m_values[mid].time <= year_end)
        {
            end_pos = mid;
            left = mid + 1;  // より後方を探す
        }
        else
        {
            right = mid - 1;
        }
    }
    
    // ========== 該当範囲を一括コピー ==========
    int count = end_pos - start_pos + 1;
    if(count > 0)
    {
        ArrayResize(values, count);
        for(int i = 0; i < count; i++)
        {
            values[i] = m_values[start_pos + i];
        }
    }
}

//+------------------------------------------------------------------+
//| Aegis追加機能の実装（Phase 1）                                    |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| EA停止処理                                                         |
//| MT5: ExpertRemove()                                               |
//| MT4: GlobalVariable経由で停止フラグ設定                           |
//+------------------------------------------------------------------+
void EXMQL::StopEA()
{
#ifdef __MQL5__
   ExpertRemove();
#else
   // MT4: GlobalVariableで停止フラグを設定
   GlobalVariableSet("Aegis_Stop", (double)TimeCurrent());
   Print("[EXMQL] EA停止要求: Aegis_Stop フラグを設定しました");
#endif
}

//+------------------------------------------------------------------+
//| 致命的エラー判定                                                   |
//| 戻り値: true=致命的エラー（EA停止すべき）                          |
//|        false=一時的エラー（リトライ可能）                         |
//+------------------------------------------------------------------+
bool EXMQL::IsFatalError(int error_code)
{
   switch(error_code)
   {
      // ========== 口座関連 ==========
      case 65:     // ERR_ACCOUNT_DISABLED (MT4)
      case 10017:  // TRADE_RETCODE_ERROR (MT5)
      
      // ========== システム関連 ==========
      case 4:      // ERR_NOT_ENOUGH_MEMORY
      case 4013:   // ERR_INVALID_POINTER_TYPE
      
      // ========== 取引パラメータ関連 ==========
      case 4051:   // ERR_INVALID_FUNCTION_PARAMVALUE
      case 10014:  // TRADE_RETCODE_INVALID_FILL (MT5)
      
      // ========== シンボル関連 ==========
      case 4106:   // ERR_UNKNOWN_SYMBOL
      
         return true;
      
      default:
         return false;
   }
}



//+------------------------------------------------------------------+

#endif
