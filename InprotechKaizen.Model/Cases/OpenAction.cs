using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using InprotechKaizen.Model.Rules;

namespace InprotechKaizen.Model.Cases
{
    [Table("OPENACTION")]
    public class OpenAction
    {
        [Obsolete("For persistence only.")]
        public OpenAction()
        {
        }

        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Usage", "CA2214:DoNotCallOverridableMethodsInConstructors")]
        public OpenAction(Action action, Case @case, short cycle, string status, Criteria criteria, bool? isOpen = null)
        {
            if(action == null) throw new ArgumentNullException("action");
            if(@case == null) throw new ArgumentNullException("case");

            Action = action;
            Case = @case;
            Cycle = cycle;
            Status = status;
            Criteria = criteria;
            CriteriaId = criteria?.Id;
            CaseId = @case.Id;
            ActionId = action.Code;

            if(isOpen.HasValue)
            {
                PoliceEvents = isOpen.Value ? 1 : 0;
            }
        }

        [Column("CASEID")]
        public int CaseId { get; internal set; }

        [Key]
        [MaxLength(2)]
        [Column("ACTION")]
        public string ActionId { get; internal set; }

        [Column("CRITERIANO")]
        public int? CriteriaId { get; set; }

        [Column("CYCLE")]
        public short Cycle { get; set; }

        [MaxLength(50)]
        [Column("STATUSDESC")]
        public string Status { get; set; }

        [Column("POLICEEVENTS")]
        public decimal? PoliceEvents { get; set; }

        [Column("DATEUPDATED")]
        public DateTime? DateUpdated { get; set; }

        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Naming", "CA1716:IdentifiersShouldNotMatchKeywords", MessageId = "Case")]
        public virtual Case Case { get; internal set; }

        public virtual Action Action { get; internal set; }

        public virtual Criteria Criteria { get; set; }

        public bool IsOpen
        {
            get { return PoliceEvents == 1M; }
        }
    }
}