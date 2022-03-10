namespace InprotechKaizen.Model.Components.Policing.Monitoring
{
    public class Summary
    {
        public Summary()
        {
            InProgress = new Detail();

            OnHold = new Detail();

            WaitingToStart = new Detail();

            InError = new Detail();

            Failed = new Detail();

            Blocked = new Detail();
        }
        
        public int Total { get; set; }

        public Detail InProgress { get; set; }

        public Detail OnHold { get; set; }

        public Detail WaitingToStart { get; set; }

        public Detail InError { get; set; }

        public Detail Failed { get; set; }
        public Detail Blocked { get; set; }
    }

    public class Detail
    {
        public int Fresh { get; set; }

        public int Tolerable { get; set; }

        public int Stuck { get; set; }

        public int Total
        {
            get { return Fresh + Tolerable + Stuck; }
        }
    }
}