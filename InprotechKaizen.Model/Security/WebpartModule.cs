using System;
using System.Collections.ObjectModel;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Diagnostics.CodeAnalysis;

namespace InprotechKaizen.Model.Security
{
    [Table("MODULE")]
    public class WebpartModule
    {
        [Obsolete("For persistence only.")]
        public WebpartModule()
        {
        }

        [SuppressMessage("Microsoft.Usage", "CA2214:DoNotCallOverridableMethodsInConstructors")]
        public WebpartModule(int id, string title)
        {
            Id = id;
            Title = title;
            ProvidedByFeatures = new Collection<Feature>();
        }

        [Key]
        [Column("MODULEID")]
        public int Id { get; set; }

        [MaxLength(256)]
        [Column("TITLE")]
        public string Title { get; set; }

        [Column("TITLE_TID")]
        public int? TitleTId { get; set; }

        [MaxLength(254)]
        [Column("DESCRIPTION")]
        public string Description { get; set; }

        [Column("DESCRIPTION_TID")]
        public int? DescriptionTId { get; set; }

        public virtual Collection<Feature> ProvidedByFeatures { get; protected set; }
    }
}