using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using InprotechKaizen.Model.Security;

namespace InprotechKaizen.Model.Reports
{
    [Table("EXTERNALREPORTS")]
    public class ExternalReport
    {
        [Obsolete("For persistence only.")]
        public ExternalReport()
        {
        }

        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Usage", "CA2214:DoNotCallOverridableMethodsInConstructors")]
        public ExternalReport(SecurityTask task, string title, string description, string path)
        {
            if(task == null) throw new ArgumentNullException("task");
            if(title == null) throw new ArgumentNullException("title");

            SecurityTask = task;
            Title = title;
            Description = description;
            Path = path;
        }

        [Key]
        [Column("ID")]
        public int Id { get; set; }

        [Column("TASKID")]
        [ForeignKey("SecurityTask")]
        public short TaskId { get; set; }

        [Required]
        [MaxLength(256)]
        [Column("TITLE")]
        public string Title { get; private set; }

        [Column("DESCRIPTION")]
        [MaxLength(1000)]
        public string Description { get; private set; }

        [Required]
        [MaxLength(1000)]
        [Column("PATH")]
        public string Path { get; private set; }

        public virtual SecurityTask SecurityTask { get; protected set; }
    }
}