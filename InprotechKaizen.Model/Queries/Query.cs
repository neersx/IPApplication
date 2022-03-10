using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Queries
{
    [Table("QUERY")]
    public class Query
    {
        [Key]
        [Column("QUERYID")]
        public int Id { get; set; }

        [Column("CONTEXTID")]
        public int ContextId { get; set; }

        [Column("IDENTITYID")]
        public int? IdentityId { get; set; }

        [Required]
        [MaxLength(50)]
        [Column("QUERYNAME")]
        public string Name { get; set; }

        [MaxLength(254)]
        [Column("DESCRIPTION")]
        public string Description { get; set; }

        [Column("PRESENTATIONID")]
        [ForeignKey("Presentation")]
        public int? PresentationId { get; set; }

        [Column("FILTERID")]
        [ForeignKey("Filter")]
        public int? FilterId { get; set; }

        [Column("GROUPID")]
        [ForeignKey("Group")]
        public int? GroupId { get; set; }

        [Column("ACCESSACCOUNTID")]
        public int? AccessAccountId { get; set; }

        [Column("ISPUBLICTOEXTERNAL")]
        public bool IsPublicToExternal { get; set; }

        [Column("ISCLIENTSERVER")]
        public bool IsClientServer { get; set; }

        public virtual QueryFilter Filter { get; set; }

        public virtual QueryPresentation Presentation { get; set; }

        public virtual QueryGroup Group { get; set; }
    }
}