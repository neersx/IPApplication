using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Settings
{
    [Table("ConfigurationSettings")]
    public class ConfigSetting
    {
        [Obsolete("For persistence only.")]
        public ConfigSetting()
        {
        }

        public ConfigSetting(string key)
        {
            if (string.IsNullOrEmpty(key)) throw new ArgumentNullException("key");
            Key = key;
        }

        [Column("ID")]
        public int Id { get; set; }

        [Required]
        [MaxLength(450)]
        [Column("SETTINGKEY")]
        public string Key { get; set; }

        [Required]
        [Column("SETTINGVALUE")]
        public string Value { get; set; }
    }
}