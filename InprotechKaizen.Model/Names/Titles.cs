using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Names
{
    [Table("TITLES ")]
    public class Titles
    {
        [Obsolete("For persistence only.")]
        public Titles()
        {
        }

        [Key]
        [MaxLength(20)]
        [Column("TITLE")]
        public string Title { get; protected set; }

        [MaxLength(30)]
        [Column("FULLTITLE")]
        public string FullTitle { get; protected set; }

        [MaxLength(1)]
        [Column("GENDERFLAG")]
        public string Gender { get; set; }

        [Column("DEFAULTFLAG")]
        public bool IsDefault { get; set; }
    }
}