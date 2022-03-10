using System.ComponentModel.DataAnnotations;

namespace Inprotech.Integration.Storage
{
    public class FileStore
    {
        public int Id { get; set; }

        [Required]
        public string Path { get; set; }

        [Required]
        public string OriginalFileName { get; set; }

        public string MediaType { get; set; }
    }
}