using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using InprotechKaizen.Model.Configuration;

namespace InprotechKaizen.Model.Names
{
    [Table("TELECOMMUNICATION")]
    public class Telecommunication
    {
        [Obsolete("For persistence only")]
        public Telecommunication()
        {
            
        }

        public Telecommunication(int id)
        {
            Id = id;
        }

        [Key]
        [Column("TELECODE")]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public int Id { get; protected set; }

        [MaxLength(5)]
        [Column("ISD")]
        public string Isd { get; set; }

        [MaxLength(5)]
        [Column("AREACODE")]
        public string AreaCode { get; set; }

        [MaxLength(100)]
        [Column("TELECOMNUMBER")]
        public string TelecomNumber { get; set; }

        [MaxLength(5)]
        [Column("EXTENSION")]
        public string Extension { get; set; }

        [Column("CARRIER")]
        public int? Carrier { get; set; }

        [Column("REMINDEREMAILS")]
        public bool? ReminderEmails { get; set; }

        public virtual TableCode TelecomType { get; set; }
    }
}
