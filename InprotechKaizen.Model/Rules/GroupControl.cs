using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Rules
{
    [Table("GROUPCONTROL")]
    public class GroupControl
    {

        [Obsolete("For persistence only.")]
        public GroupControl()
        {
        }

        public GroupControl(DataEntryTask dataEntryTask, string securityGroup)
        {
            if (dataEntryTask == null) throw new ArgumentNullException(nameof(dataEntryTask));

            CriteriaId = dataEntryTask.CriteriaId;
            EntryId = dataEntryTask.Id;
            SecurityGroup = securityGroup;
        }

        [Key]
        [MaxLength(30)]
        [Column("SECURITYGROUP")]
        public string SecurityGroup { get; set; }

        [Column("CRITERIANO")]
        public int CriteriaId { get; set; }

        [Column("ENTRYNUMBER")]
        public short EntryId { get; set; }

        [Column("INHERITED")]
        public decimal? Inherited { get; set; }

        public virtual DataEntryTask Entry { get; set; }

        [NotMapped]
        public bool IsInherited
        {
            get { return Inherited == 1; }
            set { Inherited = value ? 1 : 0; }
        }
    }
}
