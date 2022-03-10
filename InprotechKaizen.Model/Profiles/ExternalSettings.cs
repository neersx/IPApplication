using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Profiles
{
    [Table("EXTERNALSETTINGS")]
    public class ExternalSettings
    {
        [Obsolete]
        public ExternalSettings()
        {
            
        }
        public ExternalSettings(string providerName)
        {
            ProviderName = providerName;
        }
        [Key]
        [Column("ID")]
        public int Id { get; set; }

        [Required]
        [MaxLength(30)]
        [Column("PROVIDERNAME")]
        public string ProviderName { get; set; }

        [Required]
        [Column("SETTINGS")]
        public string Settings { get; set; }

        [Column("ISCOMPLETE")]
        public bool IsComplete { get; set; }

        [Column("ISDISABLED")]
        public bool IsDisabled { get; set; }
    }
}
