require_relative 'mongo_data'
require_relative 'doi'

class ClaimJob
  include Sidekiq::Worker

  def perform(session_info, work)
    oauth_expired = false

    claim = Claim.new(work).to_xml
    orcid_client = OrcidClient.new(session_info)
    response = orcid_client.post(claim)
    oauth_expired = response.status >= 400

    !oauth_expired
  end
end