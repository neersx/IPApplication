using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Cases
{
    [Table("APPLICATIONBASIS")]
    public class ApplicationBasis
    {
        [Obsolete("For persistence only.")]
        public ApplicationBasis()
        {
        }

        public ApplicationBasis(string id, string name)
        {
            if(string.IsNullOrEmpty(name)) throw new ArgumentException("A valid Case Type is required.");
            if(string.IsNullOrWhiteSpace(id)) throw new ArgumentException("A valid id is required.");

            Name = name;
            Code = id;
        }

        [Column("ID")]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int Id { get; set; }

        [Key]
        [Column("BASIS")]
        [MaxLength(2)]
        public string Code { get; internal set; }

        [MaxLength(50)]
        [Column("BASISDESCRIPTION")]
        public string Name { get; set; }

        [Column("CONVENTION")]
        public decimal Convention { get; set; }

        [Column("BASISDESCRIPTION_TID")]
        public int? NameTId { get; set; }
    }
}