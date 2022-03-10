namespace Inprotech.Integration.Innography.PrivatePair
{
    public class PrivatePairApiResponse
    {
        public string Status { get; set; }

        public string Message { get; set; }
    }

    public class PrivatePairApiResponse<T> : PrivatePairApiResponse
    {
        public T Result { get; set; }
    }
}