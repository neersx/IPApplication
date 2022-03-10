using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Configuration
{
    [Table("LASTINTERNALCODE")]
    public class LastInternalCode
    {
        [Obsolete("For persistence only.")]
        public LastInternalCode()
        {
        }
        
        public LastInternalCode(string tableName)
        {
            TableName = tableName;
        }

        [Key]
        [MaxLength(18)]
        [Column("TABLENAME")]
        public string TableName { get; protected set; }

        [Column("INTERNALSEQUENCE")]
        public int InternalSequence { get; set; }

    }
}