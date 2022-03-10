using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Cases
{
    [Table("CASELIST")]
    public class CaseList
    {
        [Obsolete("For persistence only.")]
        public CaseList()
        {
        }

        public CaseList(int id, string name)
        {
            Id = id;
            Name = name;
        }

        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        [Key]
        [Column("CASELISTNO", Order = 1)]
        public int Id { get; set; }

        [Required]
        [MaxLength(50)]
        [Column("CASELISTNAME")]
        public string Name { get; set; }

        [MaxLength(254)]
        [Column("DESCRIPTION")]
        public string Description { get; set; }

        [Column("CASELISTNAME_TID")]
        public int? NameTId { get; set; }

        [Column("DESCRIPTION_TID")]
        public int? DescriptionTId { get; set; }
    }

}
