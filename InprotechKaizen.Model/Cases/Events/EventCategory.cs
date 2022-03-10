using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Cases.Events
{
    [Table("EVENTCATEGORY")]
    public class EventCategory
    {
        [Obsolete("For persistence only.")]
        public EventCategory()
        {
        }

        public EventCategory(short id)
        {
            Id = id;
        }

        [Key]
        [Column("CATEGORYID")]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public short Id { get; set; }

        [Required]
        [MaxLength(50)]
        [Column("CATEGORYNAME")]
        public string Name { get; set; }

        [Column("CATEGORYNAME_TID")]
        public int? NameTId { get; set; }

        [MaxLength(254)]
        [Column("DESCRIPTION")]
        public string Description { get; set; }

        [Column("DESCRIPTION_TID")]
        public int? DescriptionTId { get; set; }

        [Column("ICONIMAGEID")]
        public int ImageId { get; set; }

        [ForeignKey("ImageId")]
        public virtual Image IconImage { get; set; }
    }
}