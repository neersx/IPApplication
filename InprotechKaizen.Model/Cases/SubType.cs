using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Cases
{
    [Table("SUBTYPE")]
    public class SubType
    {
        [Obsolete("For persistence only.")]
        public SubType()
        {
        }

        public SubType(string id, string name)
        {
            if(string.IsNullOrEmpty(name)) throw new ArgumentException("A valid Sub Type is required.");
            if(string.IsNullOrWhiteSpace(id)) throw new ArgumentException("A valid id is required.");

            Name = name;
            Code = id;
        }

        [Column("ID")]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int Id { get; set; }

        [Key]
        [Column("SUBTYPE")]
        [MaxLength(2)]
        public string Code { get; internal set; }

        [MaxLength(50)]
        [Column("SUBTYPEDESC")]
        public string Name { get; set; }

        [Column("SUBTYPEDESC_TID")]
        public int? NameTId { get; set; }

        public override string ToString()
        {
            return Name;
        }
    }
}