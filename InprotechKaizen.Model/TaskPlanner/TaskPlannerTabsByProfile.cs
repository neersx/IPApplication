using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Diagnostics.CodeAnalysis;
using InprotechKaizen.Model.Queries;
using InprotechKaizen.Model.Security;

namespace InprotechKaizen.Model.TaskPlanner
{
    [Table("TASKPLANNERTABSBYPROFILE")]
    public class TaskPlannerTabsByProfile
    {

        [SuppressMessage("Microsoft.Usage", "CA2214:DoNotCallOverridableMethodsInConstructors")]
        [Obsolete("For persistence only.")]
        public TaskPlannerTabsByProfile()
        {

        }

        public TaskPlannerTabsByProfile(int? profileId, int queryId, int tabSequence)
        {
            ProfileId = profileId;
            QueryId = queryId;
            TabSequence = tabSequence;
        }

        public TaskPlannerTabsByProfile(Profile profile, Query query, int tabSequence)
        {
            if (query == null) throw new ArgumentNullException(nameof(query));

            ProfileId = profile?.Id;
            QueryId = query.Id;
            TabSequence = tabSequence;
        }

        [Key]
        [Column("ID")]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int Id { get; protected set; }

        [Column("PROFILEID")]
        public int? ProfileId { get; set; }

        [Column("TABSEQUENCE")]
        public int TabSequence { get; set; }

        [Column("QUERYID")]
        public int QueryId { get; set; }
        
        [Column("ISLOCKED")]
        public bool IsLocked { get; set; }

        public virtual Profile Profile { get; set; }
        public virtual Query Query { get; set; }
    }
}
