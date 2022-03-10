using System;
using System.ComponentModel.DataAnnotations;
using Inprotech.Integration.Storage;

namespace Inprotech.Integration
{
    public class Case
    {
        public int Id { get; set; }

        [Required]
        public DataSourceType Source { get; set; }

        public int? CorrelationId { get; set; }

        public string ApplicationNumber { get; set; }

        public string RegistrationNumber { get; set; }

        public string PublicationNumber { get; set; }

        public string Jurisdiction { get; set; }

        public string Version { get; set; }

        public virtual FileStore FileStore { get; set; }

        [Required]
        public DateTime CreatedOn { get; set; }

        [Required]
        public DateTime UpdatedOn { get; set; }

        [Timestamp]
        public byte[] Timestamp { get; protected set; }
    }

    public enum DataSourceType
    {
        UsptoPrivatePair,
        UsptoTsdr,
        Epo,
        IpOneData,
        File
    }
}