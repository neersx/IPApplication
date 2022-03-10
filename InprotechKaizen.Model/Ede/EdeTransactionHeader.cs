using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using InprotechKaizen.Model.Configuration;

namespace InprotechKaizen.Model.Ede
{
    [Table("EDETRANSACTIONHEADER")]
    public class EdeTransactionHeader
    {
        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Usage", "CA2214:DoNotCallOverridableMethodsInConstructors")]
        public EdeTransactionHeader()
        {
            TransactionBodies = new Collection<EdeTransactionBody>();    
            UnresolvedNames = new Collection<EdeUnresolvedName>();
        }

        [Key]
        [Column("BATCHNO")]
        public int BatchId { get; set; }

        [Column("PROCESSED")]
        public byte? Processed { get; set; }

        [Column("DATEPROCESSED")]
        public DateTime? DateProcessed { get; set; }
        
        [Column("LOGDATETIMESTAMP")]
        public DateTime? LastModified { get; set; }

        public virtual TableCode BatchStatus { get; set; }

        public virtual ICollection<EdeTransactionBody> TransactionBodies { get; protected set; }

        public virtual ICollection<EdeUnresolvedName> UnresolvedNames { get; protected set; }

        public bool IsProcessed
        {
            get { return Processed.GetValueOrDefault() > 0; }
        }
    }
}
