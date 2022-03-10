using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Configuration
{
    public class TableType
    {
        [Obsolete("For persistence only...")]
        public TableType()
        {
        }

        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Usage", "CA2214:DoNotCallOverridableMethodsInConstructors")]
        public TableType(short id)
        {
            Id = id;
            TableCodes = new Collection<TableCode>();
            SelectionTypes = new Collection<SelectionTypes>();
        }

        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        [Key]
        [Column("TABLETYPE")]
        public short Id { get; set; }

        [MaxLength(50)]
        [Column("TABLENAME")]
        public string Name { get; set; }
     
        [MaxLength(18)]
        [Column("DATABASETABLE")]
        public string DatabaseTable { get; set; }

        [Column("TABLENAME_TID")]
        public int? NameTId { get; set; }

        public virtual ICollection<TableCode> TableCodes { get; protected set; }

        public virtual ICollection<SelectionTypes> SelectionTypes { get; protected set; }
    }
}