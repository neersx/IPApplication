using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Queries
{
    [Table("QUERYFILTER")]
    public class QueryFilter
    {
        [Column("FILTERID")]
        public int Id { get; set; }

        [Required]
        [MaxLength(50)]
        [Column("PROCEDURENAME")]
        public string ProcedureName { get; set; }

        [Required]
        [Column("XMLFILTERCRITERIA")]
        public string XmlFilterCriteria { get; set; }
    }
}