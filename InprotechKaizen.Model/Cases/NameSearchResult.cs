using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using InprotechKaizen.Model.Names;

namespace InprotechKaizen.Model.Cases
{
    [Table("NAMESEARCHRESULT")]
    public class NameSearchResult
    {
        [Obsolete("For persistence only.")]
        public NameSearchResult()
        {
        }

        [Key]
        [Column("NAMEPRIORARTID")]
        public int Id { get; set; }

        [Column("PRIORARTID")]
        public int PriorArtId { get; set; }

        [Column("NAMENO")]
        public int NameId { get; set; }
        
        [MaxLength(3)]
        [Column("NAMETYPE")]
        public string NameTypeCode { get; set; }

        public virtual Name Name { get; set; }

        public virtual NameType NameType { get; set; }
    }
}