using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using InprotechKaizen.Model.Security;

namespace InprotechKaizen.Model.Profiles
{
    [Table("SETTINGVALUES")]
    public class SettingValues
    {
        [Key]
        [Column("SETTINGVALUEID")]
        public int Id { get; protected set; }

        [Column("SETTINGID")]
        public int SettingId { get; set; }

        [Column("IDENTITYID")]
        public virtual User User { get; set; }

        [Column("COLCHARACTER")]
        public string CharacterValue { get; set; }

        [Column("COLINTEGER")]
        public int? IntegerValue { get; set; }

        [Column("COLBOOLEAN")]
        public bool? BooleanValue { get; set; }

        [Column("COLDECIMAL")]
        public decimal? DecimalValue { get; set; }

        [Column("LOGDATETIMESTAMP")]
        public DateTime? TimeStamp { get; set; }

        public virtual SettingDefinition Definition { get; set; }
    }

    [Table("SETTINGDEFINITION")]
    public class SettingDefinition
    {
        [Key]
        [Column("SETTINGID")]
        public int SettingId { get; set; }

        [Column("SETTINGNAME")]
        public string Name { get; set; }

        [Column("COMMENT")]
        public string Description { get; set; }

        [Column("SETTINGNAME_TID")]
        public int? NameTid { get; set; }

        [Column("COMMENT_TID")]
        public int? DescriptionTid { get; set; }

        [Column("DATATYPE")]
        [MaxLength(1)]
        public string DataType { get; set; }
    }
   
    public static class KnownSettingIds
    {
        public const int IsExchangeInitialised = 1;
        public const int AreExchangeAlertsRequired = 2;
        public const int ExchangeMailbox = 3;
        public const int DisplayOutlookReminders = 4;
        public const int ExchangeAlertTime = 5;
        public const int PreferredCulture = 6;
        public const int HideContinuedEntries = 18;
        public const int DefaultEventNoteType = 25;
        public const int PreferredTwoFactorMode = 26;
        public const int EmailSecretKey = 27;
        public const int AppSecretKey = 28;
        public const int AppTempSecretKey = 29;
        public const int DisplayTimeWithSeconds = 19;
        public const int ResetPasswordSecretKey = 30;
        public const int AddEntryOnSave = 31;
        public const int TimeFormat12Hours = 32;
        public const int ContinueFromCurrentTime = 21;
        public const int ValueTimeOnEntry = 33;
        public const int WorkSiteLogin = 9;
        public const int WorkSitePassword = 10;
        public const int SearchReportGenerationTimeout = 34;
        public const int BillingWorksheetReportPushtoBackgroundTimeout = 24;
        public const int UseImanageWorkLink = 35;
        public const int AppsHomePage = 36;
        public const int WorkingHours = 37;
        public const int AutomaticallyRefreshTaskPlannerResults = 38;
        public const int TimePickerInterval = 39;
        public const int DurationPickerInterval = 40;
    }
}