using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Diagnostics.CodeAnalysis;

namespace InprotechKaizen.Model.TaskPlanner
{
    [Table("TASKPLANNERTAB")]
    public class TaskPlannerTab
    {
        [SuppressMessage("Microsoft.Usage", "CA2214:DoNotCallOverridableMethodsInConstructors")]
        [Obsolete("For persistence only.")]
        public TaskPlannerTab()
        {

        }

        public TaskPlannerTab(int queryId, int tabSequence, int? identityId)
        {
            QueryId = queryId;
            TabSequence = tabSequence;
            IdentityId = identityId;
        }

        [Key]
        [Column("ID")]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int Id { get; protected set; }

        [Column("QUERYID")]
        public int QueryId { get; set; }

        [Column("IDENTITYID")]
        public int? IdentityId { get; set; }

        [Column("TABSEQUENCE")]
        public int TabSequence { get; set; }
    }
}
