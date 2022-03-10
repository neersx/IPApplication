using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Diagnostics.CodeAnalysis;
using System.Linq;

namespace InprotechKaizen.Model.Configuration.Screens
{
    [Table("TOPICCONTROL")]
    public class TopicControl : IPersistableFlattenTopic
    {
        [Obsolete("For persistence only.")]
        public TopicControl()
        {
        }

        public TopicControl(string name)
        {
            if (string.IsNullOrWhiteSpace(name)) throw new ArgumentException("A valid name is required.");

            Name = name;
        }

        [SuppressMessage("Microsoft.Usage", "CA2214:DoNotCallOverridableMethodsInConstructors")]
        public TopicControl(WindowControl windowControl, string name) : this(name)
        {
            WindowControl = windowControl ?? throw new ArgumentNullException(nameof(windowControl));
            WindowControlId = windowControl.Id;
        }

        [SuppressMessage("Microsoft.Usage", "CA2214:DoNotCallOverridableMethodsInConstructors")]
        public TopicControl(WindowControl windowControl, TabControl tabControl, string name) : this(name)
        {
            if (windowControl == null) throw new ArgumentNullException(nameof(windowControl));
            if (tabControl == null) throw new ArgumentNullException(nameof(tabControl));

            WindowControl = windowControl;
            WindowControlId = windowControl.Id;
            TabId = tabControl.Id;
        }

        [Key]
        [Column("TOPICCONTROLNO")]
        public int Id { get; protected set; }

        [Column("TABCONTROLNO")]
        public int? TabId { get; protected set; }

        [Required]
        [MaxLength(50)]
        [Column("TOPICNAME")]
        public string Name { get; set; }

        [MaxLength(100)]
        [Column("TOPICSUFFIX")]
        public string TopicSuffix { get; set; }

        [MaxLength(254)]
        [Column("TOPICTITLE")]
        public string Title { get; set; }

        [Column("TOPICTITLE_TID")]
        public int? TitleTId { get; set; }

        [MaxLength(254)]
        [Column("SCREENTIP")]
        public string ScreenTip { get; set; }

        [Column("SCREENTIP_TID")]
        public int? ScreenTipTId { get; set; }

        [Column("ISMANDATORY")]
        public bool IsMandatory { get; set; }

        [Column("ISINHERITED")]
        public bool IsInherited { get; set; }

        [Column("ROWPOSITION")]
        public short RowPosition { get; set; }

        [Column("WINDOWCONTROLNO")]
        [ForeignKey("WindowControl")]
        public int WindowControlId { get; set; }

        public virtual WindowControl WindowControl {get; set; }

        public virtual ICollection<ElementControl> ElementControls { get; protected set; } = new Collection<ElementControl>();

        public virtual ICollection<TopicControlFilter> Filters { get; protected set; } = new Collection<TopicControlFilter>();

        [NotMapped]
        public string Filter1Name
        {
            get { return Filters.ElementAtOrDefault(0)?.FilterName; }
            set
            {
                var first = Filters.ElementAtOrDefault(0);
                if (first != null)
                {
                    first.FilterName = value;
                    return;
                }

                Filters.Add(new TopicControlFilter(value, null));
            }
        }

        [NotMapped]
        public string Filter2Name
        {
            get { return Filters.ElementAtOrDefault(1)?.FilterName; }
            set
            {
                var second = Filters.ElementAtOrDefault(1);
                if (second != null)
                {
                    second.FilterName = value;
                    return;
                }

                Filters.Add(new TopicControlFilter(value, null));
            }
        }

        [NotMapped]
        public string Filter1Value
        {
            get { return Filters.ElementAtOrDefault(0)?.FilterValue; }
            set
            {
                if (Filters.ElementAtOrDefault(0) == null)
                    throw new InvalidOperationException("Filter1Name must be set first");

                Filters.ElementAt(0).FilterValue = value;
            }
        }

        [NotMapped]
        public string Filter2Value
        {
            get { return Filters.ElementAtOrDefault(1)?.FilterValue; }
            set
            {
                if (Filters.ElementAtOrDefault(1) == null)
                    throw new InvalidOperationException("Filter2Name must be set first");

                Filters.ElementAt(1).FilterValue = value;
            }
        }

        [NotMapped]
        public int? TopicId => Id;
    }

    public static class TopicControlExt
    {
        public static TopicControl InheritRuleFrom(this TopicControl dataEntryTopicControl)
        {
            if (dataEntryTopicControl == null) throw new ArgumentNullException(nameof(dataEntryTopicControl));

            var newTopicControl = CreateCopy(dataEntryTopicControl);
            newTopicControl.RowPosition = dataEntryTopicControl.RowPosition;

            newTopicControl.IsInherited = true;

            return newTopicControl;
        }

        public static TopicControl CreateCopy(this TopicControl topicControl)
        {
            if (topicControl == null) throw new ArgumentNullException(nameof(topicControl));

            return new TopicControl(topicControl.Name)
            {
                IsMandatory = topicControl.IsMandatory,
                Title = topicControl.Title,
                ScreenTip = topicControl.ScreenTip,
                Filter1Name = topicControl.Filter1Name,
                Filter2Name = topicControl.Filter2Name,
                Filter1Value = topicControl.Filter1Value,
                Filter2Value = topicControl.Filter2Value,
                TopicSuffix = Guid.NewGuid().ToString()
            };
        }
    }
}