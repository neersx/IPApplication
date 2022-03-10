using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Rules
{
    [Table("USERCONTROL")]
    public class UserControl
    {
        [Obsolete("For Persistence Only ...")]
        public UserControl()
        {
        }

        public UserControl(string userId, int criteriaId, short dataEntryTaskId)
        {
            if (string.IsNullOrWhiteSpace(userId)) throw new ArgumentNullException("userId");
            UserId = userId;
            CriteriaNo = criteriaId;
            DataEntryTaskId = dataEntryTaskId;
        }

        [Key]
        [Column("CRITERIANO", Order = 0)]
        public int CriteriaNo { get; set; }

        [Key]
        [Column("ENTRYNUMBER", Order = 1)]
        public short DataEntryTaskId { get; set; }

        [Key]
        [MaxLength(30)]
        [Column("USERID", Order = 2)]
        public string UserId { get; set; }

        [Column("INHERITED")]
        public decimal? Inherited { get; set; }

        public virtual DataEntryTask DataEntryTask { get; set; }

        [NotMapped]
        public bool IsInherited
        {
            get { return Inherited == 1; }
            set { Inherited = value ? 1 : 0; }
        }
    }
}