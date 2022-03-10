using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Names
{
    [Table("LEADSTATUSHISTORY")]
    public class LeadStatusHistory
    {
        [Obsolete("For persistence only.")]
        public LeadStatusHistory()
        {
        }

        public LeadStatusHistory(Name name)
        {
            if (name == null) throw new ArgumentNullException("name");
            Id = name.Id;
            Name = name;
        }

        [Key]
        [Column("NAMENO", Order = 1)]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public int Id { get; protected set; }

        [Key]
        [Column("LEADSTATUSID", Order = 2)]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public int LeadStatusId { get; protected set; }

        [Column("LEADSTATUS")]
        public int? LeadStatus { get; set; }

        [Column("LOGDATETIMESTAMP")]
        public DateTime LOGDATETIMESTAMP { get; set; }

        [ForeignKey("Id")]
        public virtual Name Name { get; set; }
    }
}