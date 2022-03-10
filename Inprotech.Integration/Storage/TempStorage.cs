using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Inprotech.Integration.Storage
{
    [Table("TempStorage")]
    public class TempStorage
    {
        [Obsolete("For persistence only.")]
        public TempStorage()
        {

        }

        public TempStorage(string data)
        {
            if (data == null) throw new ArgumentNullException("data");
            Value = data;
        }

        [Key]
        [Column("Id")]
        public long Id { get; protected set; }

        [Column("Data")]
        public string Value { get; set; }
        
        [Timestamp]
        /* refer to RecoveryComplete for use of this field */
        public byte[] RowVersion { get; protected set; }  
    }
}
