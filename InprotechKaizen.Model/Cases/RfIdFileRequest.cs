using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Cases
{
    [Table("RFIDFILEREQUEST")]
    public class RfIdFileRequest
    {
        [Key]
        [Column("REQUESTID")]
        public int Id { get; set; }

        [Column("CASEID")]
        public int? CaseId { get; set; }

        [Column("FILELOCATION")]
        public int FileLocationId { get; set; }

        [Column("EMPLOYEENO")]
        public int? EmployeeId { get; set; }

        [Column("DATEOFREQUEST")]
        public DateTime? DateOfRequest { get; set; }

        [Column("DATEREQUIRED")]
        public DateTime? DateRequired { get; set; }

        [MaxLength(254)]
        [Column("REMARKS")]
        public string Remarks { get; set; }

        [Column("PRIORITY")]
        public int? Priority { get; set; }

        [Column("STATUS")]
        public short? Status { get; set; }

        [Column("ISSELFSEARCH")]
        public bool? IsSelfSearch { get; set; }
    }
}