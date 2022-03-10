using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Cases
{
    [Table("FAMILYSEARCHRESULT")]
    public class FamilySearchResult
    {
        [Key]
        [Column("FAMILYPRIORARTID")]
        public int Id { get; set; }

        [MaxLength(20)]
        [Column("FAMILY")]
        public string FamilyId { get; set; }

        [Column("PRIORARTID")]
        public int PriorArtId { get; set; }

        public virtual Family Family { get; set; }
    }
}