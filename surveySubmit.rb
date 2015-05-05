require "capybara"
require "capybarista"
require "JSON"

Capybara.ignore_hidden_elements = true
Capybara.configure do |config|
  config.default_wait_time = 4
end

module WaitForAjax  # from https://robots.thoughtbot.com/automatically-wait-for-ajax-with-capybara
  def wait_for_ajax
    Timeout.timeout(Capybara.default_wait_time) do
      loop until finished_all_ajax_requests?
    end
  end

  def finished_all_ajax_requests?
    session.evaluate_script('jQuery.active').zero?
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
		
		while !session.first(:css, ".gform_next_button").nil?
			if session.first(:css, ".gform_next_button")
				session.find(:css, '.gform_next_button').click
				# wait_for_ajax
				# session.execute_script("console.log(jQuery('#choice_1_27_1') )")
			end

		end
		return self
	end

	def checkboxIdArray
		allCheckboxes = session.all(:css, ".gfield_checkbox input", :visible => false)
		return allCheckboxes.map {|c| c[:id]}
	end

	def checkboxFill(checkboxArray)
		Capybara.ignore_hidden_elements = false
		times = checkboxArray.length
		timesToCheck = rand(times*2)
		timesToCheck.times do |i|
			@sampledID = checkboxArray.sample
			session.execute_script("jQuery('#'+'#{@sampledID}').prop('checked',true); ")
			sleep 3
			# session.execute_script("jQuery('#'+#{@sampledID}).prop('checked',true);")
			# session.check("#" + sampledID, :visible => false)
		end
		# Capybara.ignore_hidden_elements = true
	end


end


session = Capybara::Session.new :selenium

surveyRobot = SurveyFiller.new(session)

checkboxes = surveyRobot.goToLastPage("http://audubonsurvey.org/").checkboxIdArray
surveyRobot.checkboxFill(checkboxes)


