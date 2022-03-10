using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Names
{
    [Table("LEADDETAILS")]
    public class LeadDetails
    {
        [Obsolete("For persistence only.")]
        public LeadDetails()
        {
        }

        public LeadDetails(Name name)
        {
            if (name == null) throw new ArgumentNullException("name");
            Id = name.Id;
            Name = name;
        }

        [Key]
        [Column("NAMENO")]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public int Id { get; protected set; }

        [Column("LEADSOURCE")]
        public int? LeadSource { get; set; }

        [Column("ESTIMATEDREV")]
        public decimal? EstimatedRev { get; set; }

        [MaxLength(3)]
        [Column("ESTREVCURRENCY")]
        public string EstimatedRevCurrency { get; set; }

        [Column("ESTIMATEDREVLOCAL")]
        public decimal? EstimatedRevLocal { get; set; }

        [MaxLength(3000)]
        [Column("COMMENTS")]
        public string Comments { get; set; }

        [ForeignKey("Id")]
        public virtual Name Name { get; protected set; }
    }
}