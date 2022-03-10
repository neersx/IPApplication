using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Queries
{
    [Table("TOPICDATAITEMS")]
    public class TopicDataItems
    {
        [Key]
        [Column("TOPICID", Order = 1)]
        public int TopicId { get; set; }

        [Key]
        [Column("DATAITEMID", Order = 2)]
        public int DataItemId { get; set; }

        [MaxLength(50)]
        [Column("LOGUSERID")]
        public string LogUserId { get; set; }

        [Column("LOGIDENTITYID")]
        public int? LogIdentityId { get; set; }

        [Column("LOGTRANSACTIONNO")]
        public int? LogTransactionNo { get; set; }

        [Column("LOGDATETIMESTAMP")]
        public DateTime? LogDateTimeStamp { get; set; }
        
        [MaxLength(128)]
        [Column("LOGAPPLICATION")]
        public string LogApplication { get; set; }

        [Column("LOGOFFICEID")]
        public int? LogOfficeId { get; set; }
        
        public virtual QueryDataItem QueryDataItem { get; set; }
    }
}
