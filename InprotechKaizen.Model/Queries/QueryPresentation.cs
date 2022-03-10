using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Queries
{
    [Table("QUERYPRESENTATION")]
    public class QueryPresentation
    {
        [Key]
        [Column("PRESENTATIONID")]
        public int Id { get; set; }

        [Column("CONTEXTID")]
        public int ContextId { get; set; }

        [Column("IDENTITYID")]
        public int? IdentityId { get; set; }

        [Column("ISDEFAULT")]
        public bool IsDefault { get; set; }

        [Column("FREEZECOLUMNID")]
        public int? FreezeColumnId { get; set; }

        [MaxLength(30)]
        [Column("PRESENTATIONTYPE")]
        public string PresentationType { get; set; }

        [Column("ACCESSACCOUNTID")]
        public int? AccessAccountId { get; set; }
    }
}