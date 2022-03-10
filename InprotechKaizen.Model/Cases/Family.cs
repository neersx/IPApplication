using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Cases
{
    [Table("CASEFAMILY")]
    public class Family
    {
        [Obsolete("For persistence only.")]
        public Family()
        {
        }

        public Family(string id, string name)
        {
            if(string.IsNullOrEmpty(name)) throw new ArgumentException("A valid family is required.");
            if(string.IsNullOrWhiteSpace(id)) throw new ArgumentException("A valid id is required.");

            Name = name;
            Id = id;
        }

        [Key]
        [MaxLength(20)]
        [Column("FAMILY")]
        public string Id { get; set; }

        [MaxLength(254)]
        [Column("FAMILYTITLE")]
        public string Name { get; set; }

        [Column("FAMILYTITLE_TID")]
        public int? NameTId { get; set; }

        public override string ToString()
        {
            return Name;
        }
    }
}