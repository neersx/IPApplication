using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Queries
{
    [Table("QUERYGROUP")]
    public class QueryGroup
    {

        [Obsolete("For persistence only.")]
        public QueryGroup()
        {
        }

        public QueryGroup(int id, string name, int contextId)
        {
            Id = id;
            GroupName = name;
            ContextId = contextId;
        }

        [Key]
        [Column("GROUPID")]
        public int Id { get; set; }

        [Column("CONTEXTID")]
        public int ContextId { get; set; }

        [Required]
        [MaxLength(50)]
        [Column("GROUPNAME")]
        public string GroupName { get; set; }

        [Column("GROUPNAME_TID")]
        public int? GroupName_Tid { get; set; }

        [Column("DISPLAYSEQUENCE")]
        public short? DisplaySequence { get; set; }
    }
}
