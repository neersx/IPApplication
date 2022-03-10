using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using Inprotech.Integration.Documents;

namespace Inprotech.Integration.AutomaticDocketing
{
    public enum DocumentEventStatus
    {
        Pending,
        Processing,
        Processed
    }

    public class DocumentEvent
    {
        [Obsolete("For persistence only")]
        public DocumentEvent()
        {
            
        }

        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Usage", "CA2214:DoNotCallOverridableMethodsInConstructors")]
        public DocumentEvent(Document document)
        {
            if (document == null) throw new ArgumentNullException(nameof(document));

            DocumentId = document.Id;
            Document = document;
        }

        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public int DocumentId { get; set; }

        public int? CorrelationId { get; set; }

        public int? CorrelationEventId { get; set; }

        public int? CorrelationCycle { get; set; }

        [Required]
        public DocumentEventStatus Status { get; set; }

        [Required]
        public DateTime CreatedOn { get; set; }

        [Required]
        public DateTime UpdatedOn { get; set; }

        public virtual Document Document { get;  set; }
    }
}
