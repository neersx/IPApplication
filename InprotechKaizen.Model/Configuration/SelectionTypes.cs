﻿using System;
﻿using System.ComponentModel.DataAnnotations;
﻿using System.ComponentModel.DataAnnotations.Schema;

﻿namespace InprotechKaizen.Model.Configuration
{
    [Table("SELECTIONTYPES")]
    public class SelectionTypes
    {
        [Obsolete("For persistence only...")]
        public SelectionTypes()
        {
        }

        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Usage", "CA2214:DoNotCallOverridableMethodsInConstructors")]
        public SelectionTypes(TableType tableType)
        {
            TableType = tableType;
        }

        [Key]
        [MaxLength(50)]
        [Column("PARENTTABLE", Order = 1)]
        public string ParentTable { get; set; }

        [Key]
        [Column("TABLETYPE", Order = 2)]
        public short TableTypeId { get; set; }

        [Column("MINIMUMALLOWED")]
        public short ? MinimumAllowed { get; set; }

        [Column("MAXIMUMALLOWED")]
        public short ? MaximumAllowed { get; set; }

        [Column("MODIFYBYSERVICE")]
        public bool ModifiableByService { get; set; }

        public virtual TableType TableType { get; protected set; }
    }
}