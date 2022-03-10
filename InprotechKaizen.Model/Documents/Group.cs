using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Documents
{
    [Table("GROUPS")]
    public class Group
    {
        [Obsolete("For persistence only.")]
        public Group() { }

        public Group(int code, string description)
        {
            Code = code;
            Name = description;
        }

        [Key]
        [Column("GROUP_CODE")]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public int Code { get; set; }

        [Required]
        [MaxLength(40)]
        [Column("GROUP_NAME")]
        public string Name { get; set; }

        [Column("GROUP_NAME_TID")]
        public int? NameTId { get; set; }
    }
}
