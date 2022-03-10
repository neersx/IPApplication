using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using InprotechKaizen.Model.Rules;

namespace InprotechKaizen.Model.Configuration.Screens
{
    [Table("WINDOWCONTROL")]
    public class WindowControl
    {
        [Obsolete("For persistence only.")]
        public WindowControl()
        {
        }

        public WindowControl(int criteriaId, string name)
        {
            if(string.IsNullOrWhiteSpace(name)) throw new ArgumentException("A valid name is required.");

            CriteriaId = criteriaId;
            Name = name;
        }

        public WindowControl(int criteriaId, short entryId, string name = "WorkflowWizard")
        {
            if (string.IsNullOrWhiteSpace(name)) throw new ArgumentException("A valid name is required.");

            CriteriaId = criteriaId;
            EntryNumber = entryId;
            Name = name;
        }

        public WindowControl(Criteria criteria, short entryNumber) : this(criteria.Id, entryNumber)
        {
        }

        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        [Column("WINDOWCONTROLNO")]
        public int Id { get; protected set; }

        [Column("CRITERIANO")]
        public int? CriteriaId { get; protected internal set; }

        [Column("NAMECRITERIANO")]
        public int? NameCriteriaId { get; protected internal set; }

        [Required]
        [MaxLength(50)]
        [Column("WINDOWNAME")]
        public string Name { get; protected internal set; }

        [Column("ENTRYNUMBER")]
        public short? EntryNumber { get; protected internal set; }

        [Column("ISINHERITED")]
        public bool IsInherited { get; set; }
        
        public virtual ICollection<TopicControl> TopicControls { get; set; } = new Collection<TopicControl>();
    }
}