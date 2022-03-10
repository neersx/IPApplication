using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Names
{
    [Table("ORGANISATION")]
    public class Organisation
    {
        [Obsolete("For persistence only.")]
        public Organisation()
        {
        }

        public Organisation(int id)
        {
            Id = id;
        }

        [Key]
        [Column("NAMENO")]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public int Id { get; set; }

        [MaxLength(30)]
        [Column("REGISTRATIONNO")]
        public string RegistrationNo { get; set; }

        [MaxLength(30)]
        [Column("VATNO")]
        public string VATNo { get; set; }

        [MaxLength(254)]
        [Column("INCORPORATED")]
        public string Incorporated { get; set; }

        [Column("PARENT")]
        public int? ParentId { get; set; }

        [MaxLength(30)]
        [Column("STATETAXNO")]
        public string StateTaxNo { get; set; }

        [Column("NUMBEROFSTAFF")]
        public int? NumberOfStaff { get; set; }

        public virtual Name Parent { get; set; }

        [Required]
        public Name Name { get; protected set; }
    }
}