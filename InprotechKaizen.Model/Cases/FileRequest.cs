using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Cases
{
    [Table("FILEREQUEST")]
    public class FileRequest
    {
        [Key]
        [Column("CASEID", Order = 0)]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public int CaseId { get; set; }

        [Key]
        [Column("FILELOCATION", Order = 1)]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public int FileLocationId { get; set; }

        [Key]
        [Column("SEQUENCENO", Order = 2)]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public short SequenceNo { get; set; }

        [Column("EMPLOYEENO")]
        public int? EmployeeId { get; set; }

        [Column("FILEPARTID")]
        public short? FilePartId { get; set; }

        [Column("DATEOFREQUEST")]
        public DateTime? DateOfRequest { get; set; }

        [Column("DATEREQUIRED")]
        public DateTime? DateRequired { get; set; }

        [MaxLength(254)]
        [Column("REMARKS")]
        public string Remarks { get; set; }

        [Column("RESOURCENO")]
        public int? ResourceId { get; set; }

        [Column("PRIORITY")]
        public int? Priority { get; set; }

        [Column("STATUS")]
        public short? Status { get; set; }
    }
}