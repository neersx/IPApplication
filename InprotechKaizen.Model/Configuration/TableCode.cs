using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Configuration
{
    [Table("TABLECODES")]
    public class TableCode
    {
        [Obsolete("For persistence only.")]
        public TableCode()
        {
        }

        public TableCode(int id, short tableTypeId, string name, string userCode = null)
        {
            if(string.IsNullOrEmpty(name)) throw new ArgumentException("A valid table code description is required.");

            Id = id;
            TableTypeId = tableTypeId;
            Name = name;
            UserCode = userCode;
        }

        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        [Key]
        [Column("TABLECODE")]
        public int Id { get; set; }

        [Column("TABLETYPE")]
        public short TableTypeId { get; set; }

        [MaxLength(80)]
        [Column("DESCRIPTION")]
        public string Name { get; set; }

        [Column("DESCRIPTION_TID")]
        public int? NameTId { get; set; }

        [MaxLength(50)]
        [Column("USERCODE")]
        public string UserCode { get; set; }

        public virtual TableType TableType { get; protected set; }

        public override string ToString()
        {
            return Name;
        }
    }
}