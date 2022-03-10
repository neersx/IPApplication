using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Configuration
{
    [Table("FREQUENCY")]
    public class Frequency
    {
        [Obsolete("For persistence only.")]
        public Frequency()
        {
        }

        public Frequency(int id, int frequencyType, string name, int frequencyDays)
        {
            if(string.IsNullOrEmpty(name)) throw new ArgumentException("A valid table code description is required.");

            Id = id;
            FrequencyType = frequencyType;
            Name = name;
            FrequencyDays = frequencyDays;
        }

        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        [Key]
        [Column("FREQUENCYNO")]
        public int Id { get; set; }

        [Column("FREQUENCYTYPE")]
        public int FrequencyType { get; set; }

        [Required]
        [MaxLength(30)]
        [Column("DESCRIPTION")]
        public string Name { get; set; }

        [Column("DESCRIPTION_TID")]
        public int? NameTId { get; set; }

        [Column("FREQUENCY")]
        public int FrequencyDays { get; set; }

        [Required]
        [MaxLength(1)]
        [Column("PERIODTYPE")]
        public string PeriodType { get; set; }

        public override string ToString()
        {
            return Name;
        }
    }
}