using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Policing
{
    [Table("POLICINGQUEUE_VIEW")]
    public class PolicingQueueView
    {
        [Obsolete("This is a database view")]
        public PolicingQueueView()
        {
        }

        [Key]
        public int RequestId { get; set; }

        [MaxLength(8)]
        public string Status { get; set; }

        public DateTime Requested { get; set; }

        public int IdleFor { get; set; }

        [MaxLength(254)]
        public string User { get; set; }

        [MaxLength(50)]
        public string UserKey { get; set; }

        public int? CaseId { get; set; }

        [MaxLength(30)]
        public string CaseReference { get; set; }

        public int? EventId { get; set; }

        public int? EventControlDescriptionTId { get; set; }

        [MaxLength(100)]
        public string EventControlDescription { get; set; }

        public int? EventDescriptionTId { get; set; }

        [MaxLength(100)]
        public string EventDescription { get; set; }

        [MaxLength(50)]
        public string ValidActionName { get; set; }

        public int? ValidActionNameTId { get; set; }

        [MaxLength(50)]
        public string ActionName { get; set; }

        public int? ActionNameTId { get; set; }

        public int? CriteriaId { get; set; }

        [MaxLength(254)]
        public string CriteriaDescription { get; set; }
        public int? CriteriaDescriptionTId { get; set; }

        [MaxLength(12)]
        public string TypeOfRequest { get; set; }

        [MaxLength(50)]
        public string PropertyName { get; set; }
        public int? PropertyNameTId { get; set; }
        [MaxLength(60)]
        public string Jurisdiction { get; set; }
        public int? JurisdictionTId { get; set; }
        public DateTime? ScheduledDateTime { get; set; }
        [MaxLength(40)]
        public string PolicingName { get; set; }

        public Int16? Cycle { get; set; }
    }
}