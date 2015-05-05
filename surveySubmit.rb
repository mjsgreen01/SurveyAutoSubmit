require "capybara"
require "capybarista"
require "JSON"



module WaitForAjax  # from https://robots.thoughtbot.com/automatically-wait-for-ajax-with-capybara
  def wait_for_ajax
    Timeout.timeout(Capybara.default_wait_time) do
      loop until finished_all_ajax_requests?
    end
  end

  def finished_all_ajax_requests?
    page.evaluate_script('jQuery.active').zero?
  end
end



class SurveyFiller
	include WaitForAjax  #maybe change include to 'extend'

	attr_accessor :session

	def initialize(session)
		@session = session
	end

	def goToLastPage(url)
		session.visit url

		while session.first(:css, ".gform_next_button")
			session.find(:css, '.gform_next_button').click
			wait_for_ajax
		end
	end

	def checkboxIdArray
		allCheckboxes = session.all(:css, ".gfield_checkbox input", :visible => false)
		return allCheckboxes.map {|c| c[:id]}
	end

end


Capybara.ignore_hidden_elements = true
