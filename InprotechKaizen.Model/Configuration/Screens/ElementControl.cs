using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Diagnostics.CodeAnalysis;

namespace InprotechKaizen.Model.Configuration.Screens
{
    [Table("ELEMENTCONTROL")]
    public class ElementControl
    {
        [Obsolete("For persistence only.")]
        public ElementControl()
        {
        }

        public ElementControl(string elementName, string fullLabel, string shortLabel, bool isHidden)
        {
            if (string.IsNullOrWhiteSpace(elementName)) throw new ArgumentNullException(nameof(elementName));
            if (string.IsNullOrWhiteSpace(fullLabel)) throw new ArgumentNullException(nameof(fullLabel));

            ElementName = elementName;
            FullLabel = fullLabel;
            ShortLabel = shortLabel;
            IsHidden = isHidden;
        }

        [SuppressMessage("Microsoft.Usage", "CA2214:DoNotCallOverridableMethodsInConstructors")]
        public ElementControl(TopicControl topicControl, string elementName, string fullLabel, string shortLabel, bool isHidden) : this(elementName, fullLabel, shortLabel, isHidden)
        {
            TopicControl = topicControl ?? throw new ArgumentNullException(nameof(topicControl));
            TopicControlId = topicControl.Id;
        }

        [Key]
        [Column("ELEMENTCONTROLNO")]
        public int Id { get; protected set; }

        [Required]
        [MaxLength(50)]
        [Column("ELEMENTNAME")]
        public string ElementName { get; protected internal set; }

        [MaxLength(254)]
        [Column("FULLLABEL")]
        public string FullLabel { get; protected internal set; }

        [Column("ISHIDDEN")]
        public bool IsHidden { get; protected internal set; }

        [MaxLength(254)]
        [Column("SHORTLABEL")]
        public string ShortLabel { get; protected set; }

        [Column("TOPICCONTROLNO")]
        [ForeignKey("TopicControl")]
        public int TopicControlId { get; set; }

        public virtual TopicControl TopicControl { get; set; }
    }
}